/*
stat effects from a fraymotif are temporary. wear off after battle.
so, players, player snapshots AND gameEntities will have to have an array of applied fraymotifs.
and their getPower, getHP etc stats must use these.
at start AND end of battle (can't be too careful), wipe applied fraymotifs
*/
function Fraymotif(aspects, name,tier, flavorText){
    this.aspects = aspects; //expect to be an array
    this.name = name;
    this.tier = tier;
    //flavor text acts as a template, with ENEMIES and CASTERS and ALLIES and ENEMY being replaced.
    //you don't call flavor text directly, instead expecting the use of the fraymotif to return something
    //based on it.
    //make sure ENEMY is the same for all effects, dunkass.
    this.flavorText = flavorText;  //will generate it procedurally if not set, otherwise things like sprites will have it hand made.
    this.used = false; //when start fight, set to false. set to true when used. once per fight
  	this.effects = [];  //each effect is a target, a revive, a statName
  	this.baseValue = 50 * this.tier;
	   if(this.tier == 3) this.baseValue = 1000;


    this.toString  = function(){
      return this.name;
    }

	this.addEffectsForPlayers = function(players){
		for(var i = 0; i<players.length; i++){
			var effect = new FraymotifEffect();
			effect.setEffectForPlayer(players[i]);
			this.effects.push(effect);
		}
	}

	this.getCasters = function(owner, allies){
		//first check to see if all aspects are included in the allies array.
		var casters = [owner];
		var aspects = [];
		var living = findLivingPlayers(allies); //dead men use no fraymotifs. (for now)
		for(var i = 1; i<this.aspects.length; i++){ //skip the first aspect, because that's owner.
			var a = this.aspects[i];
			casters.push(getRandomElementFromArray(findAllAspectPlayers(allies, a))); //ANY player that matches my aspect can do this.
		}
		return casters;  //eventually do smarter things, like only allow to cast buff hp if heals are needed or anybody is dead.
	}

  this.processFlavorText = function(owner, casters, enemy, enemies){
      //if this.flavorText is null, we need to create it from our effects.
      /*
        when creating procedural flavor text, don't just blindly concat effects.
        need to grab similar effects and combine.“Damages an Enemy based on how WILLFUL, STRONG, CALM, and FAST, the casters are compared to their enemy.”
        do regexp replacement on the phrases the toString for effects generates.
      */

      //once i have flavor text, either procedural or hard coded
      /*
        Do regex replacment on CASTERS, ENEMY, FRAYMOTIF
      */
      if(!this.flavorText) this.flavorText = this.proceduralFlavorText();
      var phrase = "The CASTERS do FRAYMOTIF on the ENEMY. ";//shitty example.
      phrase += this.flavorText;
      return this.replaceKeyWords(phrase, owner, casters, enemy, enemies);
  }

  this.proceduralFlavorText = function(){
    //first, compress the procedural effects text
    //then, do a regexp on the parts.
    //care about stats, not aspects. can mention aspects  as well somehow.
    //a soothing ASPECTWORD descends upon the allies of CASTERS, healing them.
    var base = this.superCondenseEffectsText();
    console.log("replace base with regexp shit")
    return base;
  }

  this.superCondenseEffectsText = function(){
    var effectTypes = {};  //hash coded by effectType damage0 vs damage1 vs buff0. first element is template
    for(var i = 0; i<4; i++){
      effectTypes["effect"+i] = []
    }
    for(var i = 0; i<this.effects.length; i++){
      var e = this.effects[i];
        if(effectTypes["effect"+ e.target].length == 0)   effectTypes["effect"+ e.target].push(e.toStringSimple())
        //no repeats
        if( effectTypes["effect"+ e.target].indexOf(e.statName) == -1) effectTypes["effect"+ e.target].push(e.statName)
    }
    //now i have a hash of all effect types and the stats i'm applying to them.
    var retArray = [];
    for(var i = 0; i<4; i++){
      var stats = [];
      if(effectTypes["effect"+i].length > 0){
        stats = effectTypes["effect"+i]
        var template = stats[0];
        stats.removeFromArray(template);
        retArray.push(template.replace(new RegExp("STAT","g"), [stats.slice(0, -1).join(', '), stats.slice(-1)[0]].join(stats.length < 2 ? '' : ' and ')))
      }
    }
    console.log(["retArray is: ",retArray]);
    return [retArray.slice(0, -1).join(', '), retArray.slice(-1)[0]].join(retArray.length < 2 ? '' : ' and ')
  }
  //if i have multiple effects that do similar things, condense them.
  this.condenseEffectsText = function(){
        /*
          If two effects both DAMAGE an ENEMY, then I want to generate text where it lists the types of damage.
          “Damages an Enemy based on how WILLFUL, STRONG, CALM, and FAST, the casters are compared to their enemy.”
        */
        //8 main types of effects, damage/buff and 0-4
        var effectTypes = {};  //hash coded by effectType damage0 vs damage1 vs buff0. first element is template
        for(var i = 0; i<4; i++){
          effectTypes["damage"+i] = []
          effectTypes["buff"+i] = []
        }
        for(var i = 0; i<this.effects.length; i++){
          var e = this.effects[i];
          if(e.damageInsteadOfBuff){
            if(effectTypes["damage"+ e.target].length == 0)   effectTypes["damage"+ e.target].push(e.toString())
            //no repeats
            if( effectTypes["damage"+ e.target].indexOf(e.statName) == -1) effectTypes["damage"+ e.target].push(e.statName)
          }else{
            if(effectTypes["buff"+ e.target].length == 0)   effectTypes["buff"+ e.target].push(e.toString())
            if( effectTypes["buff"+ e.target].indexOf(e.statName) == -1) effectTypes["buff"+ e.target].push(e.statName)
          }
        }
        //now i have a hash of all effect types and the stats i'm applying to them.
        var retArray = [];
        for(var i = 0; i<4; i++){
          var stats = [];
          if(effectTypes["damage"+i].length > 0){
            stats = effectTypes["damage"+i]
            var template = stats[0];
            stats.removeFromArray(template);
            retArray.push(template.replace(new RegExp("STAT","g"), [stats.slice(0, -1).join(', '), stats.slice(-1)[0]].join(stats.length < 2 ? '' : ' and ')))
          }
          if(effectTypes["buff"+i].length > 0){
            stats = effectTypes["buff"+i]
            var template = stats[0];
            stats.removeFromArray(template);
            retArray.push(template.replace(new RegExp("STAT","g"), [stats.slice(0, -1).join(', '), stats.slice(-1)[0]].join(stats.length < 2 ? '' : ' and ')));
          }
        }
        return [retArray.slice(0, -1).join(', '), retArray.slice(-1)[0]].join(retArray.length < 2 ? '' : ' and ')

  }

  this.replaceKeyWords = function(phrase, owner, casters, enemy, enemies){
    //ret= ret.replace(new RegExp(this.lettersToReplace[i][0], "g"),replace);
    phrase = phrase.replace(new RegExp("OWNER","g"), owner.htmlTitleBasic())
    phrase = phrase.replace(new RegExp("CASTERS","g"), getPlayersTitlesBasic(casters))
    phrase = phrase.replace(new RegExp("ENEMY","g"), enemy.htmlTitleBasic())
    phrase = phrase.replace(new RegExp("ENEMIES","g"), getPlayersTitlesBasic(enemies))
    phrase = phrase.replace(new RegExp("FRAYMOTIF","g"), this.name)
    return phrase
  }

	//allies is NOT just who is helping to cast the fraymotif. it is everyone.
	this.useFraymotif = function(owner, allies, enemies){
		var casters = this.getCasters(owner, allies);
		console.log(casters);
		if(casters.length != aspects.length) return;

    //ALL effects that target a single enemy target the SAME enemy.
    var enemy = getRandomElementFromArray(enemies);
		for(var i = 0; i<this.effects.length; i++){
			//effect knows how to apply itself. pass it baseValue.
			this.effects[i].applyEffect(owner, allies, casters,  enemy, enemies, this.baseValue);
		}
    return this.processFlavorText(owner, casters, enemy, enemies);
	}
}



//no global functions any more. bad pastJR.
function FraymotifCreator(session){
  this.session = session;


  this.getRandomBreathName = function(){
      var names = ["Gale", "Feather", "Breathless","Jetstream", "Hurricane", "Tornado"," Kansas", "Breath", "Breeze", "Twister", "Storm", "Wild", "Inhale", "Windy", "Skylark", "Fugue", "Pneumatic", "Wheeze", "Forward", "Vertical", "Whirlwind", "Jetstream"];
      return getRandomElementFromArray(names)
  }

  this.getRandomRageName = function(){
      var names = ["Rage", "Barbaric", "Impossible", "Juggalo","Horrorcore" ,"Madness", "Carnival", "Mirthful", "Screaming", "Berserk", "MoThErFuCkInG", "War", "Haze", "Murder", "Furioso", "Aggressive", "ATBasher", "Violent", "Unbound", "Purple", "Unholy", "Hateful", "Fearful", "Inconceivable", "Impossible"];
      return getRandomElementFromArray(names)
  }

  this.getRandomLifeName = function(){
      var names = ["Life" ,"Pastoral", "Green", "Relief", "Healing", "Plant", "Vitality", "Growing", "Garden", "Multiplying", "Rising", "Survival", "Phoenix", "Respawn", "Mangrit", "Animato", "Gaia", "Increasing", "Overgrowth", "Jungle", "Harvest", "Lazarus"];
      return getRandomElementFromArray(names)
  }

  this.getRandomHopeName = function(){
      var names = ["Hope","Fake", "Belief", "Bullshit", "Determination", "Burn", "Stubborn", "Religion", "Will", "Hero", "Undying", "Dream", "Sepulchritude", "Prophet", "Apocryphal"];
      return getRandomElementFromArray(names)
  }

  this.getRandomVoidName = function(){
      var randBonus = "<span class = 'void'>" + getRandomElementFromArray(interests) +  "</span>"
      var names = ["Undefined", "Void","Disappearification","Pumpkin", "Nothing", "Emptiness", "Invisible", "Dark", "Hole", "Solo", "Silent", "Alone", "Night", "Null", "[Censored]", "[???]", "Vacuous", "Abyss", "Noir", "Blank", "Tenebrous", "Antithesis", "404"];
      return getRandomElementFromArray(names)+ randBonus;
  }

  this.getRandomLightName = function(){
      var names = ["Lucky", "Light", "Knowledge", "Blinding", "Brilliant", "Break", "Blazing", "Glow", "Flare", "Gamble", "Omnifold", "Apollo", "Helios", "Scintillating", "Horseshoe", "Leggiero", "Star", "Kindle", "Gambit", "Blaze"];
      return getRandomElementFromArray(names)
  }

  this.getRandomMindName = function(){
      var names = ["Mind", "Modulation", "Shock", "Awe", "Coin", "Judgement", "Mind", "Decision", "Spark", "Path", "Trial", "Variations", "Thunder", "Logical", "Telekinetic", "Brainiac", "Hysteria", "Deciso", "Thesis", "Imagination",  "Psycho", "Control", "Execution", "Bolt"];
      return getRandomElementFromArray(names)
  }

  this.getRandomHeartName = function(){
      var names = ["Heart","Soul", "Jazz", "Blues", "Spirit", "Splintering", "Clone", "Self", "Havoc", "Noble", "Animus", "Astral", "Shatter", "Breakdown", "Ethereal", "Beat", "Pulchritude"];
      return getRandomElementFromArray(names)
  }

  this.getRandomBloodName = function(){
      var names = ["Blood", "Chain", "Flow", "Charge", "Awakening", "Ichorial", "Friendship", "Trusting", "Clotting", "Union", "Bleeding", "Team", "Transfusion", "Pulse", "Sanguine", "Positive", "Negative", "Cruor", "Vim", "Chorus", "Iron", "Ichorial", "Fever", "Heat"];
      return getRandomElementFromArray(names)
  }

  this.getRandomDoomName = function(){
      var names = ["Dark", "Broken", "Meteoric", "Diseased","Fate", "Doomed", "Inevitable", "Doom", "End", "Final", "Dead", "Ruin", "Rot", "Coffin", "Apocalypse", "Morendo", "Smorzando", "~Ath", "Armistyx", "Grave", "Corpse", "Ashen", "Reaper", "Diseased", "Armageddon", "Cursed"];
      return getRandomElementFromArray(names)
  }

  this.getRandomTimeName = function(){
      var names = ["Time","Paradox", "Moment", "Foregone", "Reset", "Endless", "Temporal", "Shenanigans", "Clock", "Tick-Tock", "Spinning", "Repeat", "Rhythm", "Redshift",  "Epoch", "Beatdown", "Slow", "Remix", "Clockwork", "Lock", "Eternal"];
      return getRandomElementFromArray(names)
  }

  this.getRandomSpaceName = function(){
      var names = ["Canon","Space","Frogs", "Location", "Spatial", "Universe", "Infinite", "Spiral", "Physics", "Star", "Galaxy", "Nuclear", "Atomic", "Nucleus", "Horizon", "Event", "CROAK", "Spatium", "Squiddle", "Engine", "Meteor", "Gravity", "Crush"];
      return getRandomElementFromArray(names)
  }

  this.getRandomNameForAspect = function(aspect){
    console.log(aspect);
    var ret = "";
    if(aspect == "Blood") ret = this.getRandomBloodName();
    if(aspect == "Mind") ret = this.getRandomMindName();
    if(aspect == "Rage") ret =  this.getRandomRageName();
    if(aspect == "Time") ret =  this.getRandomTimeName();
    if(aspect == "Void") ret =  this.getRandomVoidName();
    if(aspect == "Heart") ret =  this.getRandomHeartName();
    if(aspect == "Breath") ret =  this.getRandomBreathName();
    if(aspect == "Light") ret =  this.getRandomLightName();
    if(aspect == "Space") ret =  this.getRandomSpaceName();
    if(aspect == "Hope") ret =  this.getRandomHopeName();
    if(aspect == "Life") ret =  this.getRandomLifeName();
    if(aspect == "Doom") ret =  this.getRandomDoomName();
    return getFontColorFromAspect(aspect) + ret + "</font>"
  }

  this.getRandomMusicWord = function(aspect){ //takes in an aspect for color
    var names = ["Fortississimo", "Leitmotif", "Liberetto", "Sarabande", "Serenade", "Anthem", "Crescendo", "Vivace", "Encore", "Vivante", "Allegretto", "Fugue", "Choir", "Nobilmente", "Hymn", "Eroico", "Chant", "Mysterioso", "Diminuendo", "Perdendo", "Staccato", "Allegro", "Caloroso", "Nocturne"];
    names = names.concat(["Cadenza", "Cadence", "Waltz", "Concerto", "Finale", "Requiem", "Coda", "Dirge", "Battaglia", "Leggiadro", "Capriccio", "Presto", "Largo", "Accelerando", "Polytempo", "Overture", "Reprise", "Orchestra"])

    var ret = getRandomElementFromArray(names);
    if(Math.seededRandom() > 0.5){
      return "<span style='color:" + getColorFromAspect(aspect) + "'>" + ret.toLowerCase()+"</span>";  //tacked onto existin word
    }else{
      return " " + ret; //extra word
    }
  }

  this.getFraymotifName = function(players, tier){
    var name = "";
    var indexOfMusic = players.length-1;  //used to be random now always at end.
    if(players.length == 1){
      indexOfMusic = getRandomInt(0,tier-1);
      for(var i = 0; i < tier; i++){
        var musicWord = "";
        if(i == indexOfMusic) musicWord = this.getRandomMusicWord(players[i].aspect);
        name += this.getRandomNameForAspect(players[0].aspect) + musicWord +" ";
      }
    }else{

      for(var i = 0; i<players.length; i++){
        var musicWord = "";
        if(i == indexOfMusic) musicWord = this.getRandomMusicWord(players[i].aspect);
        name += this.getRandomNameForAspect(players[i].aspect) + musicWord +  " ";
      }
    }
    return name;
  }

  //classes is between 0 and aspects.length. each aspect is paired with a class.
  //should there be no class to pair with, random effect based on aspect
  //otherwise, effect is based on both class and aspect
  this.makeFraymotif = function(players,tier){ //asumming first player in that array is the owner of the framotif later on.
    var name = this.getFraymotifName(players, tier);
	var aspects = [];
	for(var i = 0; i<players.length; i++){
		if(aspects.indexOf(players[i].aspect) == -1) aspects.push(players[i].aspect); //if multiple of the same aspect is included here, just ignore.
	}
    var f= new Fraymotif(aspects, name, tier);
	f.addEffectsForPlayers(players);
	return f;
  }
}


    //effects are frozen at creation, basically.  if this fraymotif is created by a Bard of Breath in a session with a Prince of Time,
    //who then dies, and then a combo session results in an Heir of Time being able to use it with the Bard of Breath, then it'll still have the prince effect.
function FraymotifEffect(statName, target, damageInsteadOfBuff, flavorText){
	this.statName = statName;  //hp heals current hp AND revives the player.
	this.target = target; //self, allies or enemy or enemies, 0, 1, 2, 3
	this.damageInsteadOfBuff = damageInsteadOfBuff; // statName can either be applied towards damaging someone or buffing someone.  (damaging self or allies is "healing", buffing enemies is applied in the negative direction.)
	this.s = 0;  //convineience methods cause i don't think js has enums but am too lazy to confirm.
	this.a = 1;
	this.e = 2;
	this.e2 = 3;

	this.setEffectForPlayer = function(player){
		var effect = new FraymotifEffect("",this.e, true); //default to just damaging the enemy.
		if(player.class_name == "Knight") effect = getRandomElementFromArray(this.knightEffects());
    if(player.class_name == "Seer") effect = getRandomElementFromArray(this.seerEffects());
    if(player.class_name == "Bard") effect = getRandomElementFromArray(this.bardEffects());
    if(player.class_name == "Heir") effect = getRandomElementFromArray(this.heirEffects());
    if(player.class_name == "Maid") effect = getRandomElementFromArray(this.maidEffects());
    if(player.class_name == "Rogue") effect = getRandomElementFromArray(this.rogueEffects());
    if(player.class_name == "Page") effect = getRandomElementFromArray(this.pageEffects());
    if(player.class_name == "Thief") effect = getRandomElementFromArray(this.thiefEffects());
    if(player.class_name == "Sylph") effect = getRandomElementFromArray(this.sylphEffects());
    if(player.class_name == "Prince") effect = getRandomElementFromArray(this.princeEffects());
    if(player.class_name == "Witch") effect = getRandomElementFromArray(this.witchEffects());
    if(player.class_name == "Mage") effect = getRandomElementFromArray(this.mageEffects());
		this.target = effect.target;
		this.damageInsteadOfBuff = effect.damageInsteadOfBuff;
		this.statName = getRandomElementFromArray(player.getOnlyPositiveAspectAssociatedStats()).name; //TODO if I know it's a debuff, maybe debuff the things that are negative for me?
	}

	//preliminary design detailed here: https://docs.google.com/spreadsheets/d/1kam2FnKJiek6DidDpQdSnR3Wl9-vk1oZBa0pPpxlJk4/edit#gid=0
	//knights protect themselves and hurt the enemy
	this.knightEffects = function(){
		return [new FraymotifEffect("",this.s,true),new FraymotifEffect("",this.e,true),new FraymotifEffect("",this.e2,true),new FraymotifEffect("",this.s,false),new FraymotifEffect("",this.e,false) ];
	}

  //seers guide everyone to victory
  this.seerEffects = function(){
		return [new FraymotifEffect("",this.a,true),new FraymotifEffect("",this.s,false),new FraymotifEffect("",this.e,false),new FraymotifEffect("",this.e2,false),new FraymotifEffect("",this.a,false) ];
	}

  //bards are lol random.
  this.bardEffects = function(){
    var ret = [new FraymotifEffect("",this.s,false),new FraymotifEffect("",this.e,false),new FraymotifEffect("",this.e2,false),new FraymotifEffect("",this.a,false) ];
    ret = ret.concat(ret = [new FraymotifEffect("",this.s,true),new FraymotifEffect("",this.e,true),new FraymotifEffect("",this.e2,true),new FraymotifEffect("",this.a,true) ]);
    return ret;
  }

  //their aspect protects them
  this.heirEffects = function(){
		return [new FraymotifEffect("",this.s,true),new FraymotifEffect("",this.e2,true),new FraymotifEffect("",this.s,false) ];
	}

  //maids balance offense and defense???
  this.maidEffects = function(){
		return [new FraymotifEffect("",this.e2,true),new FraymotifEffect("",this.e,false),new FraymotifEffect("",this.a,false) ];
	}

  //debuff enemies, buff party, attack enemy
  this.rogueEffects = function(){
		return [new FraymotifEffect("",this.e,true),new FraymotifEffect("",this.a,false),new FraymotifEffect("",this.e,false)];
	}

  //pure support, heal allies, buff allies
  this.pageEffects = function(){
    return [new FraymotifEffect("",this.a,true),new FraymotifEffect("",this.a,false)];
  }

  //debuff enemy, buff self, damage enemy
  this.thiefEffects = function(){
    return [new FraymotifEffect("",this.e,true),new FraymotifEffect("",this.s,false),new FraymotifEffect("",this.e,false)];
  }

  //heals allies, buffs self and allies
  this.sylphEffects = function(){
    return [new FraymotifEffect("",this.e,true),new FraymotifEffect("",this.a,false),new FraymotifEffect("",this.e,false)];
  }

  //destruction
  this.princeEffects = function(){
    return [new FraymotifEffect("",this.e,true),new FraymotifEffect("",this.e2,true),new FraymotifEffect("",this.e2,false)];
  }

  //heal self, hurt enemy, debuff enemies
  this.witchEffects = function(){
    return [new FraymotifEffect("",this.e,true),new FraymotifEffect("",this.s,true),new FraymotifEffect("",this.e2,false)];
  }

  //debuff enemies heal allies
  this.mageEffects = function(){
    return [new FraymotifEffect("",this.a,true),new FraymotifEffect("",this.s,true),new FraymotifEffect("",this.e2,false),new FraymotifEffect("",this.e,false)];
  }



	this.applyEffect = function(owner,allies, casters,  enemy, enemies, baseValue){
		var strifeValue = this.processEffectValue(casters, enemies);
		var effectValue = baseValue;
		if(strifeValue < baseValue) effectValue = baseValue;
		if(strifeValue > baseValue && strifeValue < (2 * baseValue)) effectValue = 2 *baseValue;
		if(strifeValue > (2* baseValue)) effectValue = 3 *baseValue;

		//now, i need to USE this effect value.  is it doing "damage" or "buffing"?
		if(this.target == this.e || this.target == this.e2) effectValue = effectValue * -1;  //do negative things to the enemy.
		var targetArr = this.chooseTargetArr(owner, allies, casters, enemy, enemies);
    console.log(["target chosen: ", targetArr])
		if(this.damageInsteadOfBuff){
      console.log("applying damage: " + targetArr.length)
			this.applyDamage(targetArr, effectValue);
		}else{
      console.log("applying buff")
			this.applyBuff(targetArr, effectValue);
		}
	}

	this.chooseTargetArr = function(owner, allies, casters, enemy, enemies){
		console.log(["potential targets: ",owner, allies, casters, enemies]);
		if(this.target == this.s) return [owner];
		if(this.target == this.a) return allies;
		if(this.target == this.e) return [enemy]; //all effects target same enemy.
		if(this.target == this.e2) return enemies;
	}

	//targetArr is always an array, even if only 1 thing inside of it.
	this.applyDamage = function(targetArr, effectValue){
		var e = effectValue/targetArr.length;  //more potent when a single target.
    console.log(["applying damage", effectValue, targetArr.length, e])
		for(var i = 0; i<targetArr.length; i++){
			var t = targetArr[i];
			t.currentHP += e;
			t.dead = false;
		}
	}

	this.applyBuff = function(targetArr, effectValue){
		var e = effectValue/targetArr.length; //more potent when a single target.
		for(var i = 0; i<targetArr.length; i++){
			var t = targetArr[i];
			if(this.statName != "RELATIONSHIPS"){
				t[this.statName] += e;
			}else{
				for(var j = 0; i<t.relationships.length; j++){
					t.relationships[j].value += e;
				}
			}
		}
	}

	this.processEffectValue = function(casters, enemies){
		var ret = 0;
		for(var i = 0; i<casters.length; i++ ){
			var tmp = casters[i];
			if(this.statName != "RELATIONSHIPS"){
				ret += tmp[this.statName];
			}else{
				for(var j = 0; j<tmp.relationships.length; j++){
					ret += tmp.relationships[j].value
				}
			}

		}

		for(var i = 0; i< enemies.length; i++ ){
			var tmp = casters[i];
			if(this.statName != "RELATIONSHIPS"){
				ret += -1* tmp[this.statName];
			}else{
				for(varji = 0; j<tmp.relationships.length; j++){
					ret += -1* tmp.relationships[i].value
				}
			}

		}
		return ret;
	}

  this.toStringSimple = function(){
    var ret = "";
		if(this.target == this.s || this.target == this.a){
			 ret += " heals/buffs"
		}else{
			ret += " damages/debuffs"
		}

		if(this.target == 0){
			ret += " self"
		}else if(this.target ==1){
			ret += " allies"
		}else if(this.target ==2){
			ret += " an enemy"
		}else if(this.target ==3){
			ret += " all enemies"
		}
    var stat = "STAT"
		ret += " based on how " + stat + " the casters are compared to their enemy"
		return ret;
  }

	this.toString = function(){
		var ret = "";
		if(this.damageInsteadOfBuff && this.target < 2){
			 ret += " heals"
		}else if (this.damageInsteadOfBuff && this.target >= 2){
			ret += " damages"
		}else if(!this.damageInsteadOfBuff && this.target < 2){
			ret += " buffs"
		}else if(!this.damageInsteadOfBuff && this.target >= 2){
			ret += " debuffs"
		}

		if(this.target == 0){
			ret += " self"
		}else if(this.target ==1){
			ret += " allies"
		}else if(this.target ==2){
			ret += " an enemy"
		}else if(this.target ==3){
			ret += " all enemies"
		}
    var stat = "STAT"
		ret += " based on how " + stat + " the casters are compared to their enemy"
		return ret;
	}
}
