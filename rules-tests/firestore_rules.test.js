import fs from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';

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

test('AI Study Memory is owner-only, editable, bounded and clearable without deletion', async () => {
  const owner = dbFor('alice');
  const otherStudent = dbFor('bob');
  const anonymous = env.unauthenticatedContext().firestore();
  const memory = (db) => doc(db, 'users/alice/ai_study_memory/profile');
  const memoryCollection = (db) => collection(db, 'users/alice/ai_study_memory');
  const valid = {
    summary: 'गणित में सुधार',
    strengths: ['गणित'],
    weakTopics: ['बीजगणित'],
    preferredStyle: 'आसान हिंदी',
    updatedAt: serverTimestamp(),
  };

  await assertSucceeds(setDoc(memory(owner), valid));
  await assertSucceeds(getDoc(memory(owner)));
  await assertFails(getDoc(memory(otherStudent)));
  await assertFails(getDoc(memory(anonymous)));
  await assertFails(getDocs(memoryCollection(otherStudent)));
  await assertFails(getDocs(memoryCollection(anonymous)));
  await assertFails(setDoc(memory(otherStudent), valid));
  await assertFails(updateDoc(memory(otherStudent), {
    summary: 'दूसरे विद्यार्थी का बदलाव',
    updatedAt: serverTimestamp(),
  }));

  // The owner can edit the complete document through a partial update.
  await assertSucceeds(updateDoc(memory(owner), {
    summary: 'अब भौतिकी भी पढ़ रहा हूँ',
    updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(getDoc(memory(owner)));

  await assertFails(setDoc(memory(owner), { ...valid, extra: true }));
  await assertFails(setDoc(memory(owner), {
    ...valid, strengths: Array.from({ length: 13 }, (_, i) => 'topic' + i),
  }));
  await assertFails(setDoc(memory(owner), {
    ...valid, summary: 'x'.repeat(2001),
  }));

  // Clearing uses explicit empty values; the document is not deleted, so the
  // owner can safely restore memory later without changing the Rules schema.
  await assertFails(deleteDoc(memory(owner)));
  await assertSucceeds(setDoc(memory(owner), {
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
  await assertFails(getDocs(collection(dbFor('bob'), 'users/alice/ai_chats')));
  await assertFails(getDocs(collection(env.unauthenticatedContext().firestore(), 'users/alice/ai_chats')));
  await assertFails(getDocs(collection(dbFor('bob'), 'users/alice/ai_chats/chat-1/messages')));
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
  await assertSucceeds(getDocs(collection(owner, 'users/alice/ai_teacher_messages')));
  await assertFails(getDocs(collection(dbFor('bob'), 'users/alice/ai_teacher_messages')));
  await assertFails(getDocs(collection(env.unauthenticatedContext().firestore(), 'users/alice/ai_teacher_messages')));
  await assertFails(setDoc(privateDoc(dbFor('bob'), 'alice', 'ai_teacher_messages', 'm2'), {
    role: 'user', text: 'cross account', createdAt: serverTimestamp(),
  }));
});


test('onboarding, progress, plans, notes and quiz attempts are owner-only for reads, lists and writes', async () => {
  const owner = dbFor('alice');
  const otherStudent = dbFor('bob');
  const anonymous = env.unauthenticatedContext().firestore();
  const privateCollections = [
    {
      collection: 'onboarding',
      id: 'answers',
      data: { language: 'hi', _setupRequired: false },
    },
    {
      collection: 'syllabus_progress',
      id: 'math',
      data: { algebra: true },
    },
    {
      collection: 'study_plan',
      id: 'current',
      data: { dailyMinutes: 120, tasks: [] },
    },
    {
      collection: 'notes',
      id: 'note-1',
      data: {
        title: 'व्यक्तिगत नोट',
        body: 'यह केवल Alice का निजी नोट है।',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      },
    },
    {
      collection: 'quiz_attempts',
      id: 'attempt-1',
      data: {
        quizId: 'emulator-test',
        score: 1,
        total: 1,
        responses: [],
        createdAt: serverTimestamp(),
      },
    },
  ];

  for (const item of privateCollections) {
    const ownerPath = privateDoc(owner, 'alice', item.collection, item.id);
    await assertSucceeds(setDoc(ownerPath, item.data));
    await assertSucceeds(getDoc(ownerPath));

    const otherPath = privateDoc(otherStudent, 'alice', item.collection, item.id);
    await assertFails(getDoc(otherPath));
    await assertFails(getDocs(collection(otherStudent, `users/alice/${item.collection}`)));
    await assertFails(setDoc(
      privateDoc(otherStudent, 'alice', item.collection, `${item.id}-intrusion`),
      item.data,
    ));

    await assertFails(getDoc(
      privateDoc(anonymous, 'alice', item.collection, item.id),
    ));
    await assertFails(getDocs(collection(anonymous, `users/alice/${item.collection}`)));
  }
});

test('catalog is signed-in read-only and unknown collections remain denied', async () => {
  await assertSucceeds(getDoc(doc(dbFor('alice'), 'syllabus_catalog/basic')));
  await assertFails(setDoc(doc(dbFor('alice'), 'syllabus_catalog/basic'), { title: 'Injected' }));
  await assertFails(getDoc(doc(dbFor('alice'), 'users/alice/unknown_collection/x')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'syllabus_catalog/basic')));
});
