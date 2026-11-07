import fs from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-om-study-ai',
    firestore: {
      rules: fs.readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

const dbFor = (uid) => env.authenticatedContext(uid).firestore();
const privateDoc = (db, uid, collection, id = 'record') =>
  doc(db, 'users', uid, collection, id);

test('private profile is readable only by its owner', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'users/alice'), {
      uid: 'alice', displayName: 'Alice', email: 'alice@example.test',
      language: 'hi', selectedGoals: [], createdAt: serverTimestamp(),
    });
  });
  await assertSucceeds(getDoc(doc(dbFor('alice'), 'users/alice')));
  await assertFails(getDoc(doc(dbFor('bob'), 'users/alice')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'users/alice')));
});

test('AI Study Memory accepts bounded owner writes and rejects cross-account or malformed writes', async () => {
  const memory = (db) => doc(db, 'users/alice/ai_study_memory/profile');
  const valid = {
    summary: 'गणित में सुधार',
    strengths: ['गणित'],
    weakTopics: ['बीजगणित'],
    preferredStyle: 'आसान हिंदी',
    updatedAt: serverTimestamp(),
  };
  await assertSucceeds(setDoc(memory(dbFor('alice')), valid));
  await assertSucceeds(getDoc(memory(dbFor('alice'))));
  await assertFails(getDoc(memory(dbFor('bob'))));
  await assertFails(setDoc(memory(dbFor('bob')), valid));
  await assertFails(setDoc(memory(dbFor('alice')), { ...valid, extra: true }));
  await assertFails(setDoc(memory(dbFor('alice')), {
    ...valid, strengths: Array.from({ length: 13 }, (_, i) => 'topic' + i),
  }));
  await assertFails(setDoc(memory(dbFor('alice')), {
    ...valid, summary: 'x'.repeat(2001),
  }));
  // The profile editor clears curated memory by replacing every field with an
  // explicit empty value; this must remain allowed without deleting the doc.
  await assertSucceeds(setDoc(memory(dbFor('alice')), {
    summary: '', strengths: [], weakTopics: [], preferredStyle: '',
    updatedAt: serverTimestamp(),
  }));
});

test('AI chat and messages are owner-only, bounded, and immutable after creation', async () => {
  const owner = dbFor('alice');
  const chat = doc(owner, 'users/alice/ai_chats/chat-1');
  await assertSucceeds(setDoc(chat, {
    title: 'Physics', createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(), lastMessageAt: serverTimestamp(),
  }));
  const message = doc(owner, 'users/alice/ai_chats/chat-1/messages/message-1');
  await assertSucceeds(setDoc(message, {
    role: 'user', text: 'Ohm law समझाइए', createdAt: serverTimestamp(),
  }));
  await assertFails(getDoc(doc(dbFor('bob'), 'users/alice/ai_chats/chat-1')));
  await assertFails(getDoc(doc(dbFor('bob'), 'users/alice/ai_chats/chat-1/messages/message-1')));
  await assertFails(setDoc(doc(dbFor('bob'), 'users/alice/ai_chats/chat-1/messages/foreign'), {
    role: 'user', text: 'intrusion', createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(owner, 'users/alice/ai_chats/chat-1/messages/bad-role'), {
    role: 'admin', text: 'not allowed', createdAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(message, { text: 'edited' }));
  await assertFails(deleteDoc(message));
});

test('legacy AI Teacher history allows valid owner creates but no edits or deletes', async () => {
  const owner = dbFor('alice');
  const legacy = privateDoc(owner, 'alice', 'ai_teacher_messages', 'm1');
  await assertSucceeds(setDoc(legacy, {
    role: 'user', text: 'पुराना सवाल', createdAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(legacy, { text: 'changed' }));
  await assertFails(deleteDoc(legacy));
  await assertFails(setDoc(privateDoc(dbFor('bob'), 'alice', 'ai_teacher_messages', 'm2'), {
    role: 'user', text: 'cross account', createdAt: serverTimestamp(),
  }));
});

test('catalog is signed-in read-only and unknown collections remain denied', async () => {
  await assertSucceeds(getDoc(doc(dbFor('alice'), 'syllabus_catalog/basic')));
  await assertFails(setDoc(doc(dbFor('alice'), 'syllabus_catalog/basic'), { title: 'Injected' }));
  await assertFails(getDoc(doc(dbFor('alice'), 'users/alice/unknown_collection/x')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'syllabus_catalog/basic')));
});
