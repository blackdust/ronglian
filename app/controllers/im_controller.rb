class ImController < ApplicationController
  require 'digest/md5'
  layout 'im_layout'
  before_filter :check_login

  def chat_box
    ary = User.all.to_a - current_user.to_a
    ary = ary.map{|x|{id:x._id.to_s, name:x.name}}
    @component_name = "chat_box"
    @component_data = {
      chater_self: {id: 1, name: "我"},
      messages: [],
      current_user: {id:current_user.id.to_s, name: current_user.name},
      users: ary,
      _appid: ''
    }

  end

  def chat_box_group
    ary = User.all.to_a - current_user.to_a
    ary = ary.map{|x|{id:x._id.to_s, name:x.name}}
    @component_name = "chat_box_group"
    @component_data = {
      current_user: {id:current_user.id.to_s, name: current_user.name},
      users:ary,
      _appid: ''
    }
  end

  def get_sig
    _appid         = ''
    _app_token     = ''
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    sig = Digest::MD5.hexdigest(_appid + current_user.id + timestamp + _app_token)
    render :json => {:timestamp => timestamp, :sig =>sig}.to_json
  end

  protected
  def check_login
    if current_user.nil?
      redirect_to "/auth/users/developers"
    end
  end
end