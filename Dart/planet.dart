
/*

  WARNING: BEING ABANDONED FOR NOW CAUSE IT TURNS OUT MY JS WOULDN'T BE ABLE TO CALL THIS EASILY.


  
  A planet should be tailored for a specific player.
  It's land words should have one aspect related word, (only frog for space)
  and one "random" word.

  The quests inside the land should be specific to the player.  They should
  be based on class and aspect, most obviously, but also on their Interest Categories
  (which have 14 possible thingies).

  There should be quests for different internal land events.
  PreDenizen, Denizen and Post Denizen are
  categories currently in the sim.

  Lands should have a "questCompletion" rate that determines which set of quests to use.

 */
class Planet{
  String word1;
  String word2;
  List<QuestChain> questChains;
}


/*
  Dead Planets do everything a planet does, but ALSO has a timelimit
  a penalty for not winning before timelimit
  and a reward for winning before timelimit.
 */
class DeadPlanet extends Planet{

}


/*
  A QuestChain is a collection of quests that must be completed in order.

  it is associated with a reward for completion. or something. still planning.
 */
class QuestChain{
  List<Quest> quests;
  List<Reward> rewards; //most questChains only have one reward, but i won't limit things.


}


/*
  A Quest is just flavor text.
  maybe in the future it can be upgraded to be failable, maybe have a power requirement to pass?
 */
class Quest{
  String flavorText;
  List<Reward> rewards; //most quests only have one reward, but i won't limit things.
}

/*
  base level reward just calls increasePower on the player passed to it.
  but want to extend it so there is FraymotifReward, ItemReward, WeaponReward
  etc. Each will call teh super reward so that all rewards at minimum increase Power.
 */
class Reward{

  applyReward(player){
    player.increasePower();
  }

}