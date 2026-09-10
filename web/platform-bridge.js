(function(){
  const S=window.StarfallPlatform={};
  function call(name){try{if(window.CrazyGames&&CrazyGames.SDK&&typeof CrazyGames.SDK[name]==='function')CrazyGames.SDK[name]();}catch(e){}try{if(window.PokiSDK&&typeof PokiSDK[name]==='function')PokiSDK[name]();}catch(e){}}
  S.loadingFinished=()=>{try{if(window.PokiSDK&&PokiSDK.gameLoadingFinished)PokiSDK.gameLoadingFinished();}catch(e){}};
  S.gameplayStart=()=>call('gameplayStart');
  S.gameplayStop=()=>call('gameplayStop');
  S.commercialBreak=()=>{try{if(window.PokiSDK&&PokiSDK.commercialBreak)return PokiSDK.commercialBreak();}catch(e){}try{if(window.CrazyGames&&CrazyGames.SDK&&CrazyGames.SDK.ad&&CrazyGames.SDK.ad.requestAd)return CrazyGames.SDK.ad.requestAd('midgame');}catch(e){}return Promise.resolve();};
})();
