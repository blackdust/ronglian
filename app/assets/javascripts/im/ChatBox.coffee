@ChatBox = React.createClass
  getInitialState: ->
    messages: @props.data.messages
    talker_id: null

  componentDidMount: ->
    resp = RL_YTX.init(@props.data._appid)

    if 200 == resp.code 
      console.log "初始化成功 开始登陆"
      loginBuilder = new RL_YTX.LoginBuilder()
      loginBuilder.setType(1)
      loginBuilder.setUserName(@props.data.current_user.id)
      loginBuilder.setPwd()

      sig       = ""
      timestamp = ""
      jQuery.ajax
        url: "/get_sig",
        method: "POST"
      .success (msg)=>
        timestamp = msg["timestamp"]
        sig = msg["sig"]
        loginBuilder.setSig(sig)
        loginBuilder.setTimestamp(timestamp)
        @login_user(loginBuilder)
  
  login_user:(loginBuilder)->
    RL_YTX.login loginBuilder, (obj)=>
      console.log "登陆成功 设置昵称+监听即时通信消息+离线消息(解决丢失发送人)"
      uploadPersonInfoBuilder = new RL_YTX.UploadPersonInfoBuilder()
      uploadPersonInfoBuilder.setNickName(@props.data.current_user.name)
      RL_YTX.uploadPerfonInfo uploadPersonInfoBuilder
      ,
      (obj)->
      ,
      (resp)->
        console.log resp.code

    RL_YTX.onMsgReceiveListener (obj)=>
      @EV_onMsgReceiveListener(obj) 

  EV_onMsgReceiveListener:(obj)->
    you_senderNickName = obj.senderNickName
    if you_senderNickName == undefined
      you_senderNickName = obj.msgSenderNick
    console.log "收到新消息------------------------------>"
    console.log you_senderNickName
    console.log obj.msgContent
    time = new Date(parseInt(obj.msgDateCreated))
    console.log obj
    console.log time
    message =
      chater:
        time: @timestamp_format_time(time)
        name: you_senderNickName
      text: obj.msgContent
    msg_ary = @state.messages
    msg_ary.push(message)
    @setState
      messages: msg_ary


  set_talker: (id)->
    @setState
      talker_id: id

  timestamp_format_time: (now)->
    year = "" + now.getFullYear() 
    month = "" + (now.getMonth() + 1)
    day = "" + now.getDate()
    hour = "" + now.getHours()
    if hour.length == 1
      hour = "0" + hour
    minute = "" + now.getMinutes()
    if minute.length == 1
      minute = "0" + minute
    second = "" + now.getSeconds()
    if second.length == 1
      second = "0" + second
    year + "年"+ month + "月" + day + "日" +  hour + ":" + minute +  ":" +second

  render: ->
    message_list_data =
      chater_self: @props.data.chater_self
      messages: @state.messages

    message_input_area_data =
      send_message_text: @send_message_text

    <div className="chat-box">
      <MessageList data={message_list_data}/>
      <MessageInputArea data={message_input_area_data} ref="message_input_area"/>
      <UsersList data={@props.data.users} function={@set_talker}/>
    </div>

  send_message_text: ()->
    message_text = @refs.message_input_area.refs.message_input.value
    time = new Date()
    message =
      chater:
        id: @props.data.chater_self.id
        name: @props.data.chater_self.name
        time: @timestamp_format_time(time)
      text: message_text
    
    message_array = @state.messages
    message_array.push(message)

    obj = new RL_YTX.MsgBuilder()
    obj.setId(123456)
    obj.setText(message_text)
    obj.setType(1)
    obj.setReceiver(@state.talker_id)
    RL_YTX.sendMsg obj
    ,
    ()=>
      console.log "发送成功"
      @setState
        messages: message_array
      @refs.message_input_area.refs.message_input.value = ""
    ,
    (obj)->
       console.log obj
    ,
    null


UsersList = React.createClass
  render: ->
    <div className="user-list">
      {
        for item, index in @props.data
          <div className="user-item">
            <button className="ui button" onClick={@check_talk_target} data={item.id}>{item.name}</button>
          </div>  
      }
    </div>
  check_talk_target: (e)->
    jQuery(".user-item button").css("color","black")
    jQuery(e.target).css("color","red")
    talker_id = jQuery(e.target).attr("data")
    @props.function(talker_id)

MessageList = React.createClass
  render: ->
    <div className="message-list">
      {
        for item, index in @props.data.messages
          replace_text = item.text.replace(/\r?\n/g, "</br>")
          message_text = {__html: replace_text}

          chater_self = @props.data.chater_self
          if item.chater.id == chater_self.id && item.chater.name == chater_self.name
            textclass = "right-message"
          else
            textclass = "left-message"

          key = "#{index}:#{item.text}"
          <div className=textclass key={key}>
             <div className="chater">{item.chater.name + "     " + item.chater.time}</div>
             <div className="text" dangerouslySetInnerHTML={message_text} />
          </div>
      }
    </div>

MessageInputArea = React.createClass
  render: ->
    <div className="text-input">
      <div className="textarea">
        <textarea type="text" placeholder="输入你想说的话" ref="message_input" onKeyDown={@textarea_keydown} onKeyUp={@textarea_keyup}/>
      </div>
      <button className="ui button" onClick={@props.data.send_message_text}>发送</button>
    </div>

  textarea_keyup: (e)->
    @input_keycodes = []

  textarea_keydown: (e)->
    @input_keycodes ||= []
    @input_keycodes[e.keyCode] = true
    if @input_keycodes[13] && @input_keycodes[17]
      @props.data.send_message_text()
