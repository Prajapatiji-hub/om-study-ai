import fs from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, serverTimestamp, writeBatch } from 'firebase/firestore';

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

test('new profile creation requires a setup marker in the same atomic write', async () => {
  const owner = dbFor('new-student');
  const profile = doc(owner, 'users/new-student');
  const answers = doc(owner, 'users/new-student/onboarding/answers');
  const profileData = {
    uid: 'new-student',
    displayName: 'New Student',
    email: 'new-student@example.test',
    language: 'hi',
    selectedGoals: [],
    createdAt: serverTimestamp(),
  };

  await assertFails(setDoc(profile, profileData));
  await assertFails(setDoc(answers, { language: 'hi' }));

  const batch = writeBatch(owner);
  batch.set(profile, profileData);
  batch.set(answers, {
    _setupRequired: true,
    _setupCreatedAt: serverTimestamp(),
  });
  await assertSucceeds(batch.commit());
  await assertSucceeds(getDoc(profile));
  await assertSucceeds(getDoc(answers));
});

test('legacy setup answers survive restoration of a missing profile without a new gate', async () => {
  const owner = dbFor('legacy-missing-profile');
  const answers = doc(owner, 'users/legacy-missing-profile/onboarding/answers');
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'users/legacy-missing-profile/onboarding/answers'), {
      goals: ['school'],
      school_class: '12',
      language: 'hi',
    });
  });

  await assertSucceeds(setDoc(doc(owner, 'users/legacy-missing-profile'), {
    uid: 'legacy-missing-profile',
    displayName: 'Legacy Student',
    email: 'legacy@example.test',
    language: 'hi',
    selectedGoals: ['school'],
    createdAt: serverTimestamp(),
  }));
  await assertSucceeds(getDoc(answers));
  await assertSucceeds(updateDoc(answers, { language: 'en' }));
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
      // Legacy accounts have no new-signup marker; keep their data editable.
      data: { language: 'hi' },
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

test('new signup cannot clear its setup gate before all visible required answers are valid', async () => {
  const owner = dbFor('new-student');
  const answers = doc(owner, 'users/new-student/onboarding/answers');

  await assertFails(setDoc(answers, {
    _setupRequired: false,
    _setupCompletedAt: serverTimestamp(),
  }));
  await assertSucceeds(setDoc(answers, {
    _setupRequired: true,
    _setupCreatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(answers, {
    _setupRequired: false,
    _setupCompletedAt: serverTimestamp(),
  }));
  await assertFails(deleteDoc(answers));

  await assertSucceeds(setDoc(answers, {
    goals: ['school'],
    school_class: '12',
    school_board: 'cbse',
    school_stream: 'pcm',
    school_level: 'beginner',
    language: 'hi',
    hours: '2',
    time: 'morning',
    start: 'today',
    lesson_len: 'short',
    tests: 'yes',
    revision: 'weekly',
    internet: 'always',
  }, { merge: true }));
  await assertSucceeds(updateDoc(answers, {
    _setupRequired: false,
    _setupCompletedAt: serverTimestamp(),
  }));
});

test('government and ITI branches require their own visible answers before completion', async () => {
  const common = {
    language: 'hi',
    hours: '2',
    time: 'morning',
    start: 'today',
    lesson_len: 'short',
    tests: 'yes',
    revision: 'weekly',
    internet: 'always',
  };
  const scenarios = [
    {
      uid: 'govt-student',
      goal: 'govt',
      branchAnswers: {
        govt_exam: 'ssc',
        govt_level: 'beginner',
        govt_syllabus: 'yes',
      },
    },
    {
      uid: 'iti-student',
      goal: 'iti',
      branchAnswers: {
        iti_trade: 'electrician',
        iti_level: 'none',
        iti_mode: 'theory',
      },
    },
  ];

  for (const scenario of scenarios) {
    const owner = dbFor(scenario.uid);
    const answers = doc(owner, 'users/' + scenario.uid + '/onboarding/answers');
    await assertSucceeds(setDoc(answers, {
      _setupRequired: true,
      _setupCreatedAt: serverTimestamp(),
    }));
    await assertSucceeds(setDoc(answers, {
      ...common,
      goals: [scenario.goal],
    }, { merge: true }));
    await assertFails(updateDoc(answers, {
      _setupRequired: false,
      _setupCompletedAt: serverTimestamp(),
    }));
    await assertSucceeds(setDoc(answers, scenario.branchAnswers, { merge: true }));
    await assertSucceeds(updateDoc(answers, {
      _setupRequired: false,
      _setupCompletedAt: serverTimestamp(),
    }));
  }
});

test('already-completed accounts can edit setup without a new-user gate', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'users/completed-student/onboarding/answers'), {
      _setupRequired: false,
      goals: ['school'],
      school_class: '12',
      school_board: 'cbse',
      school_stream: 'pcm',
      school_level: 'beginner',
      language: 'hi',
      hours: '2',
      time: 'morning',
      start: 'today',
      lesson_len: 'short',
      tests: 'yes',
      revision: 'weekly',
      internet: 'always',
    });
  });
  const owner = dbFor('completed-student');
  await assertSucceeds(updateDoc(
    doc(owner, 'users/completed-student/onboarding/answers'),
    { goals: ['govt'] },
  ));
});

test('legacy setup documents without a marker remain editable', async () => {
  const owner = dbFor('legacy-student');
  const answers = doc(owner, 'users/legacy-student/onboarding/answers');
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'users/legacy-student'), {
      uid: 'legacy-student',
      displayName: 'Legacy Student',
      email: 'legacy@example.test',
      language: 'hi',
      selectedGoals: [],
      createdAt: serverTimestamp(),
    });
  });
  await assertSucceeds(setDoc(answers, { language: 'hi' }));
  await assertSucceeds(setDoc(answers, { goals: ['school'] }, { merge: true }));
  await assertSucceeds(setDoc(answers, { school_class: '12' }, { merge: true }));
});

test('catalog is signed-in read-only and unknown collections remain denied', async () => {
  await assertSucceeds(getDoc(doc(dbFor('alice'), 'syllabus_catalog/basic')));
  await assertFails(setDoc(doc(dbFor('alice'), 'syllabus_catalog/basic'), { title: 'Injected' }));
  await assertFails(getDoc(doc(dbFor('alice'), 'users/alice/unknown_collection/x')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'syllabus_catalog/basic')));
});
