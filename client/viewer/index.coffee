return unless window? # No execute for server-side require

module.exports.resolve=
  server:
    ($q,$localStorage,$stateParams,socket,$rootScope)->
      $q.when()
      .then ->
        $q (resolve)->
          socket.emit 'auth',$localStorage.session
          socket.removeAllListeners 'authorized'
          socket.on 'authorized',resolve
      .then ->
        $q (resolve)->
          socket.emit 'view',decodeURIComponent($stateParams.id),{res_from:100}
          socket.removeAllListeners 'getplayerstatus'
          socket.on 'getplayerstatus',(playerStatus)->
            $rootScope.title= playerStatus.title
            $rootScope.picture_url= playerStatus.picture_url
            $rootScope.default_community= playerStatus.default_community

            resolve socket

module.exports.controller= (
  $rootScope
  $localStorage
  server
  $window
  $timeout
  $state
  reader
)->
  viewModel= this

  # 次枠ある？
  server.removeAllListeners 'end_of_thread'
  server.removeAllListeners 'current'
  server.once 'end_of_thread',(chat)->
    i= 0
    interval= 1000*10
    $rootScope.waitForNext= yes

    $timeout ->
      fetchCurrent()

    fetchCurrent= ->
      # 5分で再施行停止
      return $rootScope.waitForNext= no if (not $rootScope.waitForNext) or i++ >= 30

      server.emit 'current',(playerStatus)->
        return unless playerStatus?.id
        $rootScope.waitForNext= no

        if $state.params.id != playerStatus.id
          $state.go $state.current,playerStatus,{reload:true}

      $timeout fetchCurrent,interval

  viewModel.chats= []
  server.removeAllListeners 'chat'
  server.on 'chat',(chat)->
    viewModel.chats.push chat

    $timeout ->
      $window.scrollBy 0,$window.document.body.clientHeight

  viewModel.comment= ->
    server.emit 'comment',viewModel.text
    server.once 'chat_result',(chat_result)->

    viewModel.text= ''

  viewModel.show= (event,userId)->
    url=
      if userId.match(/^\d+$/) and userId isnt '900000000'
        "http://www.nicovideo.jp/user/#{userId}"
      else
        null

    if url
      $window.open url,'user','width=465,height=465'

    return

  viewModel.read= (text)->
    reader text

  viewModel
