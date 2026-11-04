import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/ai_teacher_service.dart';
import '../theme.dart';

class AiTeacherScreen extends StatefulWidget {
  final String mode, question, selectedAnswer, correctAnswer, explanation;
  const AiTeacherScreen({super.key, this.mode='tutor', this.question='', this.selectedAnswer='', this.correctAnswer='', this.explanation=''});
  @override
  State<AiTeacherScreen> createState() => _AiTeacherScreenState();
}

class _AiTeacherScreenState extends State<AiTeacherScreen> with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _service = AiTeacherService();
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false, _listening = false;
  String _voiceLocale = 'hi-IN';
  String? _speakingMessage;
  String? _chatId;
  String _chatTitle = 'नई बातचीत';
  bool _legacy = false, _sending = false;
  bool _loadingOlder = false, _hasMoreOlder = true;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _olderDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _lastLiveDocs = [];
  Stream<QuerySnapshot<Map<String, dynamic>>>? _activeMessageStream;
  String? _error;

  User? get _user => FirebaseAuth.instance.currentUser;
  CollectionReference<Map<String,dynamic>> get _chats => FirebaseFirestore.instance.collection('users').doc(_user!.uid).collection('ai_chats');
  CollectionReference<Map<String,dynamic>> get _oldMessages => FirebaseFirestore.instance.collection('users').doc(_user!.uid).collection('ai_teacher_messages');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.mode == 'explain_question') _controller.text = 'कृपया इस प्रश्न को आसान भाषा में चरण-दर-चरण समझाइए।';
    _loadVoicePreference();
    _initializeVoice();
  }

  Future<void> _loadVoicePreference() async {
    try {
      final user = _user;
      if (user == null) return;
      final data = (await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('onboarding').doc('answers').get()).data() ?? {};
      final language = data['language'];
      final locale = language == 'en' ? 'en-US' : 'hi-IN';
      if (mounted) setState(() => _voiceLocale = locale);
    } catch (_) {
      // Keep Hindi as the safe default when no preference is saved.
    }
  }

  Future<void> _initializeVoice() async {
    try {
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      _speechReady = await _speech.initialize(
        onStatus: (status) { if (!mounted) return; setState(() => _listening = status == 'listening'); },
        onError: (error) { if (!mounted) return; setState(() { _listening = false; _error = 'आवाज़ पहचानने में समस्या हुई। कृपया दोबारा कोशिश करें।'; }); },
      );
      if (mounted) setState(() {});
    } catch (_) {
      _speechReady = false;
    }
  }

  Future<void> _toggleListening() async {
    if (_listening) { await _speech.stop(); if (mounted) setState(() => _listening = false); return; }
    if (!_speechReady) await _initializeVoice();
    if (!_speechReady) { if (mounted) setState(() => _error = 'इस फोन में Speech Recognition उपलब्ध नहीं है।'); return; }
    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() => _controller.text = result.recognizedWords);
        },
        options: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          localeId: _voiceLocale,
        ),
      );
      if (mounted) setState(() { _listening = true; _error = null; });
    } catch (_) {
      if (mounted) setState(() { _listening = false; _error = 'माइक्रोफ़ोन शुरू नहीं हो पाया। अनुमति जाँचें।'; });
    }
  }

  Future<void> _speakAnswer(String message) async {
    try {
      if (_speakingMessage == message) {
        await _tts.stop();
        if (mounted) setState(() => _speakingMessage = null);
        return;
      }
      await _tts.stop();
      if (mounted) setState(() => _speakingMessage = message);
      try {
        await _tts.setLanguage(_voiceLocale);
      } catch (_) {
        await _tts.setLanguage('en-US');
      }
      await _tts.speak(message);
      if (mounted) setState(() => _speakingMessage = null);
    } catch (_) {
      if (mounted) setState(() { _speakingMessage = null; _error = 'इस भाषा में आवाज़ उपलब्ध नहीं है।'; });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _speech.stop();
      _tts.stop();
      if (mounted) setState(() { _listening = false; _speakingMessage = null; });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speech.stop();
    _tts.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _newChat() {
    if (_sending) return;
    setState(() {
      _chatId = null;
      _chatTitle = 'नई बातचीत';
      _legacy = false;
      _olderDocs.clear();
      _lastLiveDocs = [];
      _activeMessageStream = null;
      _loadingOlder = false;
      _hasMoreOlder = true;
      _error = null;
      _controller.clear();
    });
  }

  void _openChat(String id, String title, {bool legacy=false}) {
    if (_sending) return;
    setState(() {
      _chatId = id;
      _chatTitle = title;
      _legacy = legacy;
      _olderDocs.clear();
      _lastLiveDocs = [];
      _activeMessageStream = null;
      _loadingOlder = false;
      _hasMoreOlder = true;
      _error = null;
      _controller.clear();
    });
    _activateMessageStream();
  }

  Query<Map<String, dynamic>>? get _messageQuery {
    if (_user == null || _chatId == null) return null;
    final collection = _legacy
        ? _oldMessages
        : _chats.doc(_chatId).collection('messages');
    // Document ID is a deterministic tie-breaker for equal server timestamps.
    return collection
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(50);
  }

  int _compareMessagesDescending(
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b,
  ) {
    final aTime = a.data()['createdAt'];
    final bTime = b.data()['createdAt'];
    if (aTime is Timestamp && bTime is Timestamp) {
      final byTime = bTime.compareTo(aTime);
      if (byTime != 0) return byTime;
    }
    return b.id.compareTo(a.id);
  }

  void _activateMessageStream() {
    final query = _messageQuery;
    _activeMessageStream = query?.snapshots().map((snapshot) {
      final currentDocs = snapshot.docs;
      final currentIds = currentDocs.map((doc) => doc.id).toSet();
      final knownIds = _olderDocs.map((doc) => doc.id).toSet();

      // Preserve documents that leave the newest live window as new messages
      // arrive; otherwise a moving limit(50) window could create history gaps.
      for (final previous in _lastLiveDocs) {
        if (!currentIds.contains(previous.id) && knownIds.add(previous.id)) {
          _olderDocs.add(previous);
        }
      }
      _olderDocs.sort(_compareMessagesDescending);
      _lastLiveDocs = List.of(currentDocs);
      return snapshot;
    });
  }

  Future<void> _loadOlder(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> liveDocs,
  ) async {
    if (_loadingOlder || !_hasMoreOlder || _chatId == null || _user == null) {
      return;
    }
    final requestedChatId = _chatId;
    final requestedLegacy = _legacy;
    final currentOffset = _scrollController.hasClients
        ? _scrollController.position.pixels
        : 0.0;
    final currentMax = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    final cursor = _olderDocs.isNotEmpty
        ? _olderDocs.last
        : (liveDocs.isNotEmpty ? liveDocs.last : null);
    if (cursor == null) {
      if (mounted) setState(() => _hasMoreOlder = false);
      return;
    }

    setState(() {
      _loadingOlder = true;
      _error = null;
    });
    try {
      final collection = requestedLegacy
          ? _oldMessages
          : _chats.doc(requestedChatId).collection('messages');
      final page = await collection
          .orderBy('createdAt', descending: true)
          .orderBy(FieldPath.documentId, descending: true)
          .startAfterDocument(cursor)
          .limit(50)
          .get();

      if (!mounted || _chatId != requestedChatId || _legacy != requestedLegacy) {
        return;
      }
      setState(() {
        // Merge by document ID because the live window may have advanced
        // while this page request was in flight.
        final knownIds = _olderDocs.map((doc) => doc.id).toSet();
        for (final doc in page.docs) {
          if (knownIds.add(doc.id)) _olderDocs.add(doc);
        }
        _olderDocs.sort(_compareMessagesDescending);
        _hasMoreOlder = page.docs.length == 50;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final addedExtent =
            _scrollController.position.maxScrollExtent - currentMax;
        final target = (currentOffset + addedExtent)
            .clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.jumpTo(target);
      });
    } catch (_) {
      if (mounted && _chatId == requestedChatId) {
        setState(() => _error = 'पुराने संदेश लोड नहीं हुए। फिर कोशिश करें।');
      }
    } finally {
      if (mounted && _chatId == requestedChatId) {
        setState(() => _loadingOlder = false);
      }
    }
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds:250), curve: Curves.easeOut);
    });
  }

  String _titleFor(String value) {
    final clean=value.replaceAll(RegExp(r'\s+'),' ').trim();
    return clean.length>42 ? clean.substring(0,42)+'…' : clean;
  }

  Future<String> _loadStudyMemory() async {
    final user = _user;
    if (user == null) return '';
    final root = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final parts = <String>[];
    try {
      final answers = (await root.collection('onboarding').doc('answers').get()).data() ?? {};
      const labels = {
        'school': 'स्कूल', 'govt': 'सरकारी परीक्षा', 'iti': 'ITI/कौशल',
        'hi': 'हिंदी', 'en': 'English', 'hinglish': 'Hinglish',
        'beginner': 'शुरुआती', 'medium': 'मध्यम', 'good': 'अच्छा',
      };
      final goals = answers['goals'];
      if (goals is List && goals.isNotEmpty) {
        parts.add('पढ़ाई के लक्ष्य: ${goals.map((v) => labels[v] ?? v.toString()).join(', ')}');
      }
      for (final key in ['school_class','school_board','school_stream','govt_exam','govt_year','iti_trade','language','hours','time','lesson_len','school_level','govt_level','iti_level','school_hard']) {
        final value = answers[key];
        if (value is String && value.isNotEmpty && value != '__skipped') {
          if (key == 'language') {
            // Keep the stable locale code for the Worker language selector.
            parts.add('language: $value (${labels[value] ?? value})');
          } else {
            parts.add('$key: ${labels[value] ?? value}');
          }
        }
      }
    } catch (_) {
      // Learning context is optional; never block a student's question.
    }
    try {
      final attempts = await root.collection('quiz_attempts')
          .orderBy('createdAt', descending: true).limit(3).get();
      final mistakes = <String>[];
      for (final attempt in attempts.docs) {
        final responses = attempt.data()['responses'];
        if (responses is! List) continue;
        for (final raw in responses) {
          if (raw is Map && raw['selectedIndex'] != raw['correctIndex'] &&
              raw['question'] is String) {
            mistakes.add(raw['question'] as String);
            if (mistakes.length >= 5) break;
          }
        }
        if (mistakes.length >= 5) break;
      }
      if (mistakes.isNotEmpty) {
        parts.add('हाल के टेस्ट में गलत हुए प्रश्न (इन विषयों को धैर्य से दोहराएँ): ${mistakes.join(' | ')}');
      }
    } catch (_) {
      // Older accounts may not have quiz history or its index yet.
    }
    return parts.join('\n').substring(0, parts.join('\n').length > 3000 ? 3000 : parts.join('\n').length);
  }

  Future<void> _send() async {
    final text=_controller.text.trim();
    if (text.isEmpty || _sending || _legacy) return;
    if (_user==null) { setState(()=>_error='पहले अपने खाते में लॉगिन करें।'); return; }
    if (_listening) { await _speech.stop(); }
    if (_speakingMessage != null) { await _tts.stop(); }
    setState(() { _sending = true; _error = null; _listening = false; _speakingMessage = null; });
    _controller.clear();
    try {
      final history=<Map<String,String>>[];
      final currentId=_chatId;
      if (currentId!=null) {
        final previous=await _chats.doc(currentId).collection('messages').orderBy('createdAt',descending:true).limit(8).get();
        for (final doc in previous.docs.reversed) {
          final d=doc.data();
          if ((d['role']=='user'||d['role']=='model') && d['text'] is String) history.add({'role':d['role'] as String,'text':d['text'] as String});
        }
      }
      final studyMemory = await _loadStudyMemory();
      final answer=await _service.ask(message:text,mode:widget.mode,question:widget.question,selectedAnswer:widget.selectedAnswer,correctAnswer:widget.correctAnswer,explanation:widget.explanation,history:history,studyMemory:studyMemory);
      var id=_chatId;
      final title=id==null ? _titleFor(text) : _chatTitle;
      if (id==null) {
        final ref=_chats.doc(); id=ref.id;
        await ref.set({'title':title,'createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp(),'lastMessageAt':FieldValue.serverTimestamp()});
      }
      final batch=FirebaseFirestore.instance.batch();
      final messages=_chats.doc(id).collection('messages');
      batch.set(messages.doc(),{'role':'user','text':text,'createdAt':FieldValue.serverTimestamp()});
      batch.set(messages.doc(),{'role':'model','text':answer,'createdAt':FieldValue.serverTimestamp()});
      batch.set(_chats.doc(id),{'title':title,'updatedAt':FieldValue.serverTimestamp(),'lastMessageAt':FieldValue.serverTimestamp()},SetOptions(merge:true));
      await batch.commit();
      if (!mounted) return;
      setState(() { _chatId = id; _chatTitle = title; });
      if (currentId == null) _activateMessageStream();
      _scrollBottom();
    } catch(e) {
      if (!mounted) return;
      setState(() { _error = _friendlyError(e); _controller.text = text; });
    } finally { if (mounted) setState(()=>_sending=false); }
  }

  String _friendlyError(Object e) {
    final v=e.toString().toLowerCase();
    if (v.contains('resource-exhausted')||v.contains('मुफ्त उपयोग सीमा')) return 'AI की मुफ्त उपयोग सीमा अभी पूरी हुई है। बाद में कोशिश करें।';
    if (v.contains('socketexception')||v.contains('network')||v.contains('failed host lookup')) return 'इंटरनेट कनेक्शन जाँचकर फिर कोशिश करें।';
    if (v.contains('permission-denied')) return 'नई चैट सेव करने की अनुमति नहीं मिली। नए Firestore Rules प्रकाशित होने चाहिए।';
    if (e is StateError && e.message.toString().isNotEmpty) return e.message.toString();
    return 'AI जवाब नहीं दे पाया। थोड़ी देर बाद फिर कोशिश करें।';
  }

  Future<void> _showChats() async {
    if (_user==null) return;
    await showModalBottomSheet<void>(
      context:context,isScrollControlled:true,
      builder:(sheet)=>SafeArea(child:SizedBox(
        height:MediaQuery.of(sheet).size.height*.78,
        child:Column(children:[
          ListTile(title:const Text('आपकी बातचीत',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
            trailing:IconButton(tooltip:'नई चैट',onPressed:(){Navigator.pop(sheet);_newChat();},icon:const Icon(Icons.add_comment_outlined,color:kTeal))),
          const Divider(height:1),
          Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
            stream:_chats.orderBy('updatedAt',descending:true).limit(100).snapshots(),
            builder:(context,snapshot){
              if(snapshot.hasError)return const Center(child:Text('चैट सूची लोड नहीं हुई।'));
              if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
              final docs=snapshot.data!.docs;
              return ListView(children:[
                if(docs.isEmpty) const Padding(padding:EdgeInsets.all(16),child:Text('अभी कोई नई चैट नहीं है। + दबाकर शुरू करें।')),
                ...docs.map((doc){
                  final data=doc.data(); final title=data['title'] is String ? data['title'] as String : 'बातचीत';
                  return ListTile(leading:const Icon(Icons.chat_bubble_outline),title:Text(title,maxLines:1,overflow:TextOverflow.ellipsis),subtitle:const Text('सेव की गई बातचीत'),selected:!_legacy&&_chatId==doc.id,onTap:(){Navigator.pop(sheet);_openChat(doc.id,title);});
                }),
                const Divider(),
                ListTile(leading:const Icon(Icons.history),title:const Text('पुरानी बातचीत'),subtitle:const Text('पहले सेव किए गए संदेश'),selected:_legacy,onTap:(){Navigator.pop(sheet);_openChat('legacy','पुरानी बातचीत',legacy:true);}),
              ]);
            })),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final explain=widget.mode=='explain_question';
    return Scaffold(
      appBar:AppBar(leading:IconButton(tooltip:'बातचीत सूची',onPressed:_showChats,icon:const Icon(Icons.menu)),
        title:Text(explain?'AI से प्रश्न समझें':_chatTitle,maxLines:1,overflow:TextOverflow.ellipsis),
        actions:[IconButton(tooltip:'नई चैट',onPressed:_sending?null:_newChat,icon:const Icon(Icons.add_comment_outlined))]),
      body:SafeArea(child:Column(children:[
        if(explain) Container(width:double.infinity,color:const Color(0xFFEAF4F2),padding:const EdgeInsets.all(12),
          child:Text('प्रश्न: ${widget.question}\nआपका उत्तर: ${widget.selectedAnswer}\nसही उत्तर: ${widget.correctAnswer}')),
        Expanded(child:_chatId==null ? _empty(explain) : StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
          stream:_activeMessageStream,
          builder:(context,snapshot){
            if(snapshot.hasError)return const Center(child:Text('संदेश लोड नहीं हुए।'));
            if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
            final descendingDocs = [
              ..._olderDocs,
              ...snapshot.data!.docs,
            ];
            final docs = descendingDocs.reversed.toList();
            if (docs.isEmpty) return _empty(explain);
            final showLoadOlder =
                _hasMoreOlder && (snapshot.data!.docs.length == 50 || _olderDocs.isNotEmpty);
            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: docs.length + 1 + (_sending ? 1 : 0),
              itemBuilder: (context, index) {
              if (index == 0 && showLoadOlder) {
                return Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: _loadingOlder
                        ? null
                        : () => _loadOlder(snapshot.data!.docs),
                    icon: _loadingOlder
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_less),
                    label: Text(_loadingOlder ? 'लोड हो रहा है…' : 'पुराने संदेश लोड करें'),
                  ),
                );
              }
              if (index == 0) return const SizedBox.shrink();
              final contentIndex = index - 1;
              if (contentIndex == docs.length) {
                return _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : const SizedBox.shrink();
              }
              final item=docs[contentIndex].data(); final isUser=item['role']=='user'; final message=item['text'] is String ? item['text'] as String : '';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFFD9EFEB) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD5E0DE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(message),
                      if (!isUser)
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: _speakingMessage == message
                                ? 'आवाज़ रोकें'
                                : 'जवाब सुनें',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _speakAnswer(message),
                            icon: Icon(
                              _speakingMessage == message
                                  ? Icons.stop_circle_outlined
                                  : Icons.volume_up_outlined,
                              color: kTeal,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            });
          })),
        if(_legacy) const Padding(padding:EdgeInsets.all(8),child:Text('यह पुरानी सुरक्षित बातचीत है। आगे के सवाल के लिए नई चैट शुरू करें।',style:TextStyle(color:Colors.black54))),
        if(_error!=null) Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:4),child:Text(_error!,style:const TextStyle(color:Colors.red))),
        Padding(padding:const EdgeInsets.fromLTRB(12,8,12,12),child:Row(children:[
          IconButton(tooltip:_listening?'सुनना बंद करें':'बोलकर सवाल पूछें',onPressed:(_legacy||_sending)?null:_toggleListening,icon:Icon(_listening?Icons.mic:Icons.mic_none,color:_listening?Colors.red:kTeal)),
          Expanded(child:TextField(controller:_controller,enabled:!_legacy,minLines:1,maxLines:4,maxLength:4000,decoration:InputDecoration(hintText:_legacy?'पुरानी चैट केवल पढ़ने के लिए है':_listening?'बोलिए…':'अपना सवाल लिखें…',counterText:'',border:const OutlineInputBorder()),onSubmitted:(_)=>_send())),
          const SizedBox(width:8),
          IconButton.filled(onPressed:(_sending||_legacy)?null:_send,icon:const Icon(Icons.send),color:Colors.white,style:IconButton.styleFrom(backgroundColor:kTeal)),
        ])),
      ])),
    );
  }

  Widget _empty(bool explain)=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
    const Icon(Icons.smart_toy_outlined,size:58,color:kTeal),const SizedBox(height:12),
    Text(explain?'AI इस प्रश्न को चरण-दर-चरण समझाएगा।':'नमस्ते! मैं आपका AI पढ़ाई साथी हूँ। सवाल पूछिए।',textAlign:TextAlign.center,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w600)),
    const SizedBox(height:8),const Text('महत्वपूर्ण परीक्षा या आधिकारिक जानकारी को विश्वसनीय स्रोत से जाँचें।',textAlign:TextAlign.center,style:TextStyle(fontSize:12,color:Colors.black54)),
  ])));
}
