# Dependencies
app= angular.module process.env.APP

# Public
app.directive 'read',(reader)->
  scope:
    chat: '=read'
  link: (scope,element,attrs)->
    {date,text}= scope.chat

    reader.read text if date*1000>Date.now()-1000 * 10#sec

# Private
app.factory 'voices',($window)->
  speechSynthesis= $window.speechSynthesis

  voices= []

  if speechSynthesis
    voices.push voice for voice in speechSynthesis.getVoices()

    unless voices.length
      loaded= null
      speechSynthesis.onvoiceschanged= ->
        return if loaded
        voices.push voice for voice in speechSynthesis.getVoices()
        loaded= yes

  voices= (
    for voice in ['hikari','haruka','show','takeru','santa','bear']
      {lang:'ja-VT',name:voice,emotionable:(voice isnt 'show')}
  ).concat voices

  # https://github.com/59naga/nicolive.berabou.me/issues/10
  ojtNames= [
    'CUBE370_A'
    'CUBE370_B'
    'CUBE370_C'
    'CUBE370_D'
    'mei_normal'
  ]
  voices= (
    for voice in ojtNames
      {lang:'ja-OJT',name:voice}
  ).concat voices

  voices.unshift {name:'off'}

  voices

app.factory 'reader',($localStorage,$window,$http,voices,VoiceAPI,urlPattern)->
  {
    SpeechSynthesisVoice
    SpeechSynthesisUtterance
    speechSynthesis
  }= $window

  class Reader
    read: (text)->
      speaker= (voice for voice in voices when voice.name is $localStorage.reader?.speaker)[0]

      text= text.replace urlPattern,'URL省略'

      return unless speaker?.lang
      return if text?.slice(0,3) is '/hb' # `/hb ifseetno 304`

      switch speaker.lang
        when 'ja-VT'
          voice= new VoiceAPI 'http://voicetext.berabou.me/',text,$localStorage.reader

        when 'ja-OJT'
          voice= new VoiceAPI 'http://openjtalk.berabou.me/',text,$localStorage.reader

        else
          speech= new SpeechSynthesisUtterance
          speech.text= text
          speech.lang= 'ja-JP' if speaker.lang is 'ja-JP'
          speech.voice= speaker
          speech.volume= $localStorage.reader.volume / 100
          speech.pitch= $localStorage.reader.pitch / 100
          speech.rate= $localStorage.reader.speed / 100
          speech.rate= 2 if speech.rate > 2 # if rate greater than 2, chrome has been hanging

          if speech.lang is 'ja-JP'
            speechSynthesis.speak speech

          else
            $http.get 'http://romanize.berabou.me/'+encodeURIComponent(text)
            .then (response)->
              speech.text= response.data
              speechSynthesis.speak speech

  new Reader

i= 0
app.factory 'VoiceAPI',(Bluebird,throat,Sound,$localStorage)->
  queue= (throat Bluebird) 1

  class VoiceAPI
    constructor: (url,@text,params)->
      params= JSON.parse JSON.stringify params
      params.emotion_level= '' if params.emotion is ''

      text= encodeURIComponent @text.slice 0,200
      querystring= (
        for key,value of params
          encodeURIComponent(key)+'='+encodeURIComponent(value)
      ).join('&')

      uri= url+text+'?'+querystring

      queue =>
        sound= new Sound uri
        sound.play()

  VoiceAPI
