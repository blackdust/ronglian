@ChatBoxGroup = React.createClass
  getInitialState: ->
    groups: []
    # [{"name":"name","id":"id"}]
    
  componentDidMount: ->
    _appid         = ''
    _app_token     = ''
    _user_id       =  @props.data.current_user.id

    resp = RL_YTX.init(_appid)
    if 200 == resp.code 
      console.log "初始化成功 开始登陆"
      loginBuilder = new RL_YTX.LoginBuilder()
      loginBuilder.setType(1)
      loginBuilder.setUserName(_user_id)
      loginBuilder.setPwd()
      timestamp = @now_format_time()
      sig = hex_md5(_appid + _user_id + timestamp + _app_token)
      loginBuilder.setSig(sig)
      loginBuilder.setTimestamp(timestamp)
      
      RL_YTX.login loginBuilder, (obj)=>
        console.log "登陆成功 设置昵称 + 监听即时通信消息(群组) + 离线消息(群组) + 获得所在组"
        # 
        uploadPersonInfoBuilder = new RL_YTX.UploadPersonInfoBuilder()
        uploadPersonInfoBuilder.setNickName(@props.data.current_user.name)
        RL_YTX.uploadPerfonInfo uploadPersonInfoBuilder

        # -----------------------------------------获得所在组
        obj = new RL_YTX.GetGroupListBuilder()
        obj.setPageSize(-1)
        obj.setTarget(1)
        RL_YTX.getGroupList obj
        ,
        (obj)=>
          console.log "成功获得所有的讨论组列表"
          ary = []
          for item in obj
            hash = {"name":item.name, "id":item.groupId}
            ary.push hash
          @setState
            groups: ary
        ,
        (obj)->
          console.log obj.msg
        # --------------------------------------------

        ,
        (obj)->
        ,
        (resp)->
          console.log resp.code
      # 监听im+离线消息
      RL_YTX.onMsgReceiveListener (obj)=>
        @EV_onMsgReceiveListener(obj)


  EV_onMsgReceiveListener:(obj)->
    you_senderNickName = obj.senderNickName
    if you_senderNickName == undefined
      # 这个字段用来获取离线消息 obj.msgSenderNick
      you_senderNickName = obj.msgSenderNick

    console.log "收到新消息(来自群组#{obj.msgReceiver})-------->"
    console.log you_senderNickName
    console.log obj.msgContent
    time = new Date(parseInt(obj.msgDateCreated))
    console.log time

  now_format_time: ->
    now = new Date()
    year = "" + now.getFullYear() 
    month = "" + (now.getMonth() + 1)
    if month.length == 1
      month = "0" + month
    day = "" + now.getDate()
    if day.length == 1
      day = "0" + day
    hour = "" + now.getHours()
    if hour.length == 1
      hour = "0" + hour
    minute = "" + now.getMinutes()
    if minute.length == 1
      minute = "0" + minute
    second = "" + now.getSeconds()
    if second.length == 1
      second = "0" + second
    year +  month +  day +  hour +  minute +  second

  join_group: ->
    user_ids = [@props.data.current_user.id]
    for dom in jQuery(document).find(".user-item input:checked")
      user_ids.push(jQuery(dom).attr("data"))
    group_id = null

    obj = new RL_YTX.CreateGroupBuilder()
    obj.setGroupName(jQuery(document).find(".group-name").val())
    obj.setScope(1)
    obj.setPermission(1)
    obj.setTarget(1)

    RL_YTX.createGroup obj
    ,
    (obj)=>
      group_id = obj.data
      console.log "创建群组成功"
      @invite_members(group_id, user_ids)
    ,
    (obj)->
      console.log "创建群组失败"

  invite_members: (id, members)->
    builder = new RL_YTX.InviteJoinGroupBuilder()
    builder. setGroupId(id)
    builder. setMembers(members)
    builder. setConfirm(1)
    console.log id
    RL_YTX.inviteJoinGroup builder
    ,
    ()->
      console.log "邀请成功 更新页面成员表"
    ,
    ()->
      console.log "邀请失败"

  quit_group: (event)->
    id = jQuery(ReactDOM.findDOMNode(event.target)).parent().find("p").attr("data")
    obj = new RL_YTX.QuitGroupBuilder()
    obj.setGroupId(id)
    RL_YTX.quitGroup obj
    ,
    ()->
      console.log "退出讨论组成功 没有setstate 请刷新页面"
    ,
    ()->

  render: ->
    message_input_area_data =
      send_message_text: @send_message_text
    <div className="chat-box-group">
      <MessageInputArea data={message_input_area_data} ref="message_input_area"/>
      <UsersList data={@props.data.users} function={@join_group}/>
      <GroupList data={@state.groups}     function={@quit_group}/>
    </div>

  send_message_text: ()->
    # 发送消息（群聊）
    message_text = @refs.message_input_area.refs.message_input.value
    time = new Date()

    obj = new RL_YTX.MsgBuilder()
    obj.setId(123456)
    obj.setText(message_text)
    obj.setType(1)
    obj.setReceiver(jQuery(document).find(".group-list input:checked").attr("value"))
    RL_YTX.sendMsg obj
    ,
    ()=>
      console.log "群消息发送成功"
      @refs.message_input_area.refs.message_input.value = ""
    ,
    (obj)->
       console.log obj
    ,
    null


GroupList = React.createClass
  render: ->
    <div className="group-list">
      <h3> 用户加入的讨论组</h3>
      { 
        if @props.data != null
          for item in @props.data
            <div className="user-item">
              <p data={item.id}/>{item.name}
              <input type="checkbox" value={item.id}/>
              <button className="ui button" onClick={@props.function}>退出讨论组</button>
              <button className="ui button" onClick={@get_members}>获取成员列表</button>
              <button className="ui button" onClick={@invite_other_members}>邀请其他成员</button>
            </div>
        else
          <p>没有加入讨论组</p>  
      }
    </div>

  get_members:(event)->
    id = jQuery(ReactDOM.findDOMNode(event.target)).parent().find("p").attr("data")
    obj = new RL_YTX.GetGroupMemberListBuilder()
    obj.setGroupId(id)
    obj.setPageSize(-1)
    RL_YTX.getGroupMemberList obj
    ,
    (obj)->
      console.log "获取成功"
      console.log obj
    ,
    (obj)->

  invite_other_members:(event)->
    id = jQuery(ReactDOM.findDOMNode(event.target)).parent().find("p").attr("data")
    user_ids = []
    for dom in jQuery(document).find(".user-item input:checked")
      user_ids.push(jQuery(dom).attr("data"))
    builder = new RL_YTX.InviteJoinGroupBuilder()
    builder. setGroupId(id)
    builder. setMembers(user_ids)
    builder. setConfirm(1)
    RL_YTX.inviteJoinGroup builder
    ,
    (obj)->
      console.log obj
      # 等待被邀请者同意
    ,
    (obj)->
      console.log "邀请失败"

UsersList = React.createClass
  render: ->
    <div className="user-list">
      <h3> 用户选择列表</h3>
      {
        for item in @props.data
          <div className="user-item">
            <input type="checkbox" data={item.id} value={item.name}/>{item.name}
          </div>  
      }
      <h3> 新建讨论组名称</h3>
      <input type="text" className="group-name" />
      <button className="ui button" onClick={@props.function}>邀请加入讨论组</button>
    </div>

MessageInputArea = React.createClass
  render: ->
    <div className="text-input">
      <div className="textarea">
        <textarea type="text" placeholder="输入你想说的话（先勾选一个群组）" ref="message_input" onKeyDown={@textarea_keydown} onKeyUp={@textarea_keyup}/>
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

    