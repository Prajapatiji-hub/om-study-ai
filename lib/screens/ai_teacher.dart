import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/ai_teacher_service.dart';
import '../theme.dart';

class AiTeacherScreen extends StatefulWidget {
  final String mode, question, selectedAnswer, correctAnswer, explanation;
  const AiTeacherScreen({super.key, this.mode='tutor', this.question='', this.selectedAnswer='', this.correctAnswer='', this.explanation=''});
  @override
  State<AiTeacherScreen> createState() => _AiTeacherScreenState();
}

class _AiTeacherScreenState extends State<AiTeacherScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _service = AiTeacherService();
  String? _chatId;
  String _chatTitle = 'नई बातचीत';
  bool _legacy = false, _sending = false;
  String? _error;

  User? get _user => FirebaseAuth.instance.currentUser;
  CollectionReference<Map<String,dynamic>> get _chats => FirebaseFirestore.instance.collection('users').doc(_user!.uid).collection('ai_chats');
  CollectionReference<Map<String,dynamic>> get _oldMessages => FirebaseFirestore.instance.collection('users').doc(_user!.uid).collection('ai_teacher_messages');

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'explain_question') _controller.text = 'कृपया इस प्रश्न को आसान भाषा में चरण-दर-चरण समझाइए।';
  }

  @override
  void dispose() { _controller.dispose(); _scrollController.dispose(); super.dispose(); }

  void _newChat() {
    if (_sending) return;
    setState(() { _chatId=null; _chatTitle='नई बातचीत'; _legacy=false; _error=null; _controller.clear(); });
  }

  void _openChat(String id, String title, {bool legacy=false}) {
    if (_sending) return;
    setState(() { _chatId=id; _chatTitle=title; _legacy=legacy; _error=null; _controller.clear(); });
  }

  Query<Map<String,dynamic>>? get _messageQuery {
    if (_user==null || _chatId==null) return null;
    return _legacy
      ? _oldMessages.orderBy('createdAt').limit(300)
      : _chats.doc(_chatId).collection('messages').orderBy('createdAt').limit(300);
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

  Future<void> _send() async {
    final text=_controller.text.trim();
    if (text.isEmpty || _sending || _legacy) return;
    if (_user==null) { setState(()=>_error='पहले अपने खाते में लॉगिन करें।'); return; }
    setState(()=>{_sending=true,_error=null});
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
      final answer=await _service.ask(message:text,mode:widget.mode,question:widget.question,selectedAnswer:widget.selectedAnswer,correctAnswer:widget.correctAnswer,explanation:widget.explanation,history:history);
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
      setState(()=>{_chatId=id,_chatTitle=title});
      _scrollBottom();
    } catch(e) {
      if (!mounted) return;
      setState(()=>{_error=_friendlyError(e),_controller.text=text});
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
          stream:_messageQuery!.snapshots(),
          builder:(context,snapshot){
            if(snapshot.hasError)return const Center(child:Text('संदेश लोड नहीं हुए।'));
            if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
            final docs=snapshot.data!.docs;
            if(docs.isEmpty)return _empty(explain);
            return ListView.builder(controller:_scrollController,padding:const EdgeInsets.all(12),itemCount:docs.length+(_sending?1:0),itemBuilder:(context,index){
              if(index==docs.length)return const Padding(padding:EdgeInsets.all(12),child:Align(alignment:Alignment.centerLeft,child:CircularProgressIndicator()));
              final item=docs[index].data(); final isUser=item['role']=='user'; final message=item['text'] is String ? item['text'] as String : '';
              return Align(alignment:isUser?Alignment.centerRight:Alignment.centerLeft,child:Container(constraints:const BoxConstraints(maxWidth:340),margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(13),
                decoration:BoxDecoration(color:isUser?const Color(0xFFD9EFEB):Colors.white,borderRadius:BorderRadius.circular(14),border:Border.all(color:const Color(0xFFD5E0DE))),child:SelectableText(message)));
            });
          })),
        if(_legacy) const Padding(padding:EdgeInsets.all(8),child:Text('यह पुरानी सुरक्षित बातचीत है। आगे के सवाल के लिए नई चैट शुरू करें।',style:TextStyle(color:Colors.black54))),
        if(_error!=null) Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:4),child:Text(_error!,style:const TextStyle(color:Colors.red))),
        Padding(padding:const EdgeInsets.fromLTRB(12,8,12,12),child:Row(children:[
          Expanded(child:TextField(controller:_controller,enabled:!_legacy,minLines:1,maxLines:4,maxLength:4000,decoration:InputDecoration(hintText:_legacy?'पुरानी चैट केवल पढ़ने के लिए है':'अपना सवाल लिखें…',counterText:'',border:const OutlineInputBorder()),onSubmitted:(_)=>_send())),
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
