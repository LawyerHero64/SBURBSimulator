import "dart:html";

import "../SBURBSim.dart";
enum CanonLevel {
    CANON_ONLY,
    FANON_ONLY,
    EVERYTHING_FUCKING_GOES
}

//okay, fine, yes, global variables are getting untenable.
class Session {
    //TODO some of these should just live in session mutator
    Logger logger = null;
    int session_id; //initial seed
    //var sceneRenderingEngine = new SceneRenderingEngine(false); //default is homestuck  //comment this line out if need to run sim without it crashing
    List<Player> players = <Player>[];
    FraymotifCreator fraymotifCreator = new FraymotifCreator(); //as long as FraymotifCreator has no state data, this is fine.
    //TODO all these "session summary stats" things should just be a SessionSummary object I own.

    num sessionHealth = 500 * Stats.POWER.coefficient; //grimDark players work to lower it. at 0, it crashes.  maybe have it do other things at other levels, or effect other things.
    List<Player> replayers = <Player>[]; //used for fan oc easter eggs.
    AfterLife afterLife = new AfterLife();

    bool janusReward = false;
    //if i have less than expected grist, then no frog, bucko
    int expectedGristContributionPerPlayer = 400;
    int minimumGristPerPlayer = 100; //less than this, and no frog is possible.
    CanonLevel canonLevel = CanonLevel.CANON_ONLY; //regular sessions are canon only, but wastes and eggs can change that.
    num numScenes = 0;
    bool sbahj = false;
    num hardStrength = 2000 * Stats.POWER.coefficient;
    num minFrogLevel = 13;
    num goodFrogLevel = 20;
    bool reckoningStarted = false;
    List<Player> aliensClonedOnArrival = <Player>[]; //if i'm gonna do time shenanigans, i need to know what the aliens were like when they got here.
    num timeTillReckoning = 0;
    num reckoningEndsAt = -15;
    num sessionType = -999;
    List<String> doomedTimelineReasons = <String>[]; //am I even still using this?
    num currentSceneNum = 0;
    List<Scene> scenes = <Scene>[]; //scene controller initializes all this.
    List<Scene> reckoningScenes = <Scene>[];
    List<Scene> deathScenes = <Scene>[];
    List<Scene> available_scenes = <Scene>[];
    Session parentSession = null;
    //private, should only be accessed by methods so removing a player can be invalid for time/breath
    List<Player> _availablePlayers = <Player>[]; //which players are available for scenes or whatever.
    List<ImportantEvent> importantEvents = <ImportantEvent>[];
    YellowYardResultController yellowYardController = new YellowYardResultController(); //don't expect doomed time clones to follow them to any new sessions
    SessionStats stats = new SessionStats();
    NPCHandler npcHandler = null;
    // extra fields
    Random rand;
    List<SBURBClass> available_classes_players;
    List<SBURBClass> available_classes_guardians;
    List<Aspect> available_aspects;
    List<Aspect> required_aspects;
    SessionMutator mutator;

    Session(int this.session_id) {
        PotentialSprite.initializeAShitTonOfPotentialSprites(this);
        npcHandler = new NPCHandler(this);
        mutator = SessionMutator.getInstance();
        this.setUpBosses();
        stats.initialGameEntityId = GameEntity.getIDCopy();
        print("Making sesssion $this with initialGameEntity id of ${stats.initialGameEntityId}");
        ////print("Made a new session with an id of $session_id");

        logger = Logger.get("Session: $session_id", false);

        mutator.syncToSession(this);
        this.rand = new Random(session_id);
       resetAvailableClasspects();
    }

    List<Player> getReadOnlyAvailablePlayers() {
        return new List<Player>.from(_availablePlayers);
    }

    void addAvailablePlayer(Player p) {
        _availablePlayers.add(p);
    }

    //near as i can figure logger.debug just straight up never works.
    void removeAvailablePlayer(GameEntity p1) {
        if (p1 == null || !(p1 is Player)) {
            //logger.info("i think player is null or not a player");
            return;
        }
        Player p = p1;
        //if you're dead, you're removed even if time/breath NOT doing this in old system probably caused some livly corpse bugs
        if(p.dead || !(p.aspect == Aspects.TIME || p.aspect == Aspects.BREATH || mutator.breathField)) {
            //logger.info("removing player $p");
            removeFromArray(p, _availablePlayers);
        }else {
            //logger.info("not removing player $p, i think they are a breath or time player or the breath field is active ");
        }

    }

    void resetAvailableClasspects() {
        if(canonLevel == CanonLevel.CANON_ONLY) {
            this.available_classes_players = new List<SBURBClass>.from(SBURBClassManager.canon);
            this.available_classes_guardians = new List<SBURBClass>.from(SBURBClassManager.canon);
            this.available_aspects = new List<Aspect>.from(Aspects.canon);
        }else if(canonLevel == CanonLevel.FANON_ONLY) {
            this.available_classes_players = new List<SBURBClass>.from(SBURBClassManager.fanon);
            this.available_classes_guardians = new List<SBURBClass>.from(SBURBClassManager.fanon);
            this.available_aspects = new List<Aspect>.from(Aspects.fanon);
        }else {
            this.available_classes_players = new List<SBURBClass>.from(SBURBClassManager.all);
            this.available_classes_guardians = new List<SBURBClass>.from(SBURBClassManager.all);
            this.available_aspects = new List<Aspect>.from(Aspects.all);
        }
      this.required_aspects = <Aspect>[Aspects.TIME, Aspects.SPACE];
    }

    //  //makes copy of player list (no shallow copies!!!!)
    List<Player> setAvailablePlayers(List<Player> playerList) {
        this._availablePlayers = <Player>[];
        for (num i = 0; i < playerList.length; i++) {
            //dead players are always unavailable.
            if (!playerList[i].dead) {
                this._availablePlayers.add(playerList[i]);
            }
        }
        return this._availablePlayers;
    }

    //used to live in scene controller but fuck that noise (also used to be named processScenes2)
    void processScenes(List<Player> playersInSession) {
        ////print("processing scene");
        //querySelector("#story").append("processing scene");
        setAvailablePlayers(playersInSession);
        for (num i = 0; i < this.available_scenes.length; i++) {
            Scene s = this.available_scenes[i];
            //var debugQueen = queenStrength;
            if (s.trigger(playersInSession)) {
                //session.scenesTriggered.add(s);
                this.numScenes ++;

                s.renderContent(this.newScene(s.runtimeType.toString()));
                if (!s.canRepeat) {
                    //removeFromArray(s,session.available_scenes);
                    this.available_scenes.remove(s);
                }
            }
        }

        for (num i = 0; i < this.deathScenes.length; i++) {
            Scene s = this.deathScenes[i];
            if (s.trigger(playersInSession)) {
                //	session.scenesTriggered.add(s);
                this.numScenes ++;
                s.renderContent(this.newScene(s.runtimeType.toString()));
            }
        }
    }

    void processReckoning(List<Player> playerList) {
        for (num i = 0; i < this.reckoningScenes.length; i++) {
            Scene s = this.reckoningScenes[i];
            if (s.trigger(playerList)) {
                //session.scenesTriggered.add(s);
                this.numScenes ++;
                s.renderContent(this.newScene(s.runtimeType.toString()));
            }
        }

        for (num i = 0; i < this.deathScenes.length; i++) {
            Scene s = this.deathScenes[i];
            if (s.trigger(playerList)) {
                //	session.scenesTriggered.add(s);
                this.numScenes ++;
                s.renderContent(this.newScene(s.runtimeType.toString()));
            }
        }
    }


    void destroyBlackRing() {
        npcHandler.destroyBlackRing();
    }

    Player findBestSpace() {
        List<Player> spaces = findAllAspectPlayers(this.players, Aspects.SPACE);
        if (spaces.isEmpty) return null;
        Player ret = spaces[0];
        for (num i = 0; i < spaces.length; i++) {
            if (spaces[i].landLevel > ret.landLevel) ret = spaces[i];
        }
        return ret;
    }

    Player findMostCorruptedSpace() {
        List<Player> spaces = findAllAspectPlayers(this.players, Aspects.SPACE);
        if (spaces.isEmpty) return null;
        Player ret = spaces[0];
        for (num i = 0; i < spaces.length; i++) {
            if (spaces[i].landLevel < ret.landLevel) ret = spaces[i];
        }
        return ret; //lowest space player.
    }

    ImportantEvent addImportantEvent(ImportantEvent important_event) {
        ImportantEvent alternate = this.yellowYardController.doesEventNeedToBeUndone(important_event);
        //	//print("alternate i got from yellowYardController is: " + alternate);
        if (alternate != null) {
            //	//print("returning alternate");
            if (doEventsMatch(important_event, this.afterLife.timeLineSplitsWhen, false)) this.afterLife.allowTransTimeLineInteraction();
            return alternate; //scene will use the alternate to go a different way. important event no longer happens.
        } else {
            ////print(" pushing important event and returning null");
            this.importantEvents.add(important_event);
            return null;
        }
    }

    ///frog status is part actual tadpole, part grist
    bool sickFrogCheck(Player spacePlayer) {
        //there is  a frog but it's not good enough
        bool frogSick = spacePlayer.landLevel < goodFrogLevel;
        bool frog = !noFrogCheck(spacePlayer);
        bool grist = enoughGristForFull();
        //frog is sick if it was bred wrong, or if it was nutured wrong
        return (frog && (frogSick || !grist));

    }

    bool enoughGristForFull() {
        return getTotalGrist(players) > expectedGristContributionPerPlayer * players.length;
    }

    bool enoughGristForAny() {
        return getTotalGrist(players) > minimumGristPerPlayer * players.length;
    }

    int gristPercent() {
        return (100*(getTotalGrist(players)/(minimumGristPerPlayer * players.length))).round();
    }


    bool fullFrogCheck(Player spacePlayer) {
        if(spacePlayer == null) return false;
        //there is  a frog but it's not good enough
        bool frogSick = spacePlayer.landLevel < goodFrogLevel;
        bool frog = !noFrogCheck(spacePlayer);
        bool grist = enoughGristForFull();
        //frog is full if it was bred AND nurtured right.
        return (frog && (!frogSick &&  grist));
    }

    //don't care about grist, this is already p rare. maybe it eats grim dark and not grist???
    bool purpleFrogCheck(Player spacePlayer) {
        if(spacePlayer == null) return false;
        bool frog = spacePlayer.landLevel <= (this.minFrogLevel * -1);
        bool grist = enoughGristForAny();
        return (frog && grist);
    }


    //don't care about grist, if there's no frog to deploy at all. eventually check for rings
    bool noFrogCheck(Player spacePlayer) {
        if(spacePlayer == null) return false;
        bool frog =  spacePlayer.landLevel <= this.minFrogLevel;
        bool grist = !enoughGristForAny();
        return (frog || grist);
    }

    String frogStatus() {
        String ret = "";
        Player spacePlayer = this.findBestSpace();
        Player corruptedSpacePlayer = this.findMostCorruptedSpace();
        //var spacePlayer = findAspectPlayer(this.players, "Space");
        if (purpleFrogCheck(corruptedSpacePlayer)) return "Purple Frog"; //is this...a REFRANCE???
        if (noFrogCheck(spacePlayer)){
            ret = "No Frog";
        } else if (fullFrogCheck(spacePlayer)) {
            ret = "Full Frog";
        } else if(sickFrogCheck(spacePlayer)) {
            ret = "Sick Frog";
        }else {
             logger.info("AB:  What the HELL kind of frog is this in session ${session_id}");
            ret = "??? Frog";
        }
         logger.info("AB:  Returning ending of $ret with grist of ${getAverageGrist(players)} and frog level of ${spacePlayer.landLevel}");
        return ret;
    }

    void addEventToUndoAndReset(ImportantEvent e) {
        //when I reset, need things to go the same. that includes having no ghosts interact with the session. figure out how to renable them once my event happens again.
        this.afterLife.complyWithLifeTimeShenanigans(e);
        ////print("undoing an event.");
        if (this.stats.scratched) {
            this.addEventToUndoAndResetScratch(e); //works different
            return;
        }
        if (e != null) { //will be null if undoing an undo
            this.yellowYardController.eventsToUndo.add(e);
        }
        //reinit the seed and restart the session
        //var savedPlayers = curSessionGlobalVar.players;
        this.reinit();
        Scene.createScenesForSession(curSessionGlobalVar);
        //players need to be reinit as well.
        curSessionGlobalVar.makePlayers();
        curSessionGlobalVar.randomizeEntryOrder();
        curSessionGlobalVar.makeGuardians(); //after entry order established
        checkEasterEgg(this.easterCallBack, this); //in the controller.

        return;
    }

    void easterCallBack(Session that) {
        //now that i've done that, (for seed reasons) fucking ignore it and stick the actual players in
        //after alll, i could be from a combo session.
        //but don't just hardcore replace. need to...fuck. okay, cloning aliens now.
        curSessionGlobalVar.aliensClonedOnArrival = that.aliensClonedOnArrival;
        ////print("adding this many clone aliens: " + curSessionGlobalVar.aliensClonedOnArrival.length);
        ////print(getPlayersTitles(curSessionGlobalVar.aliensClonedOnArrival));
        List<Player> aliens = <Player>[]; //if don't make copy of aliensClonedOnArrival, goes into an infinite loop as it loops on it and adds to it inside of addAliens;
        for (num i = 0; i < that.aliensClonedOnArrival.length; i++) {
            aliens.add(that.aliensClonedOnArrival[i]);
        }
        that.aliensClonedOnArrival = <Player>[]; //jettison old clones.
        addAliensToSession(curSessionGlobalVar, aliens);

        SimController.instance.restartSession(); //in controller
    }

    void addEventToUndoAndResetScratch(ImportantEvent e) {
        //print('yellow yard from scratched session');
        if (e != null) { //will be null if undoing an undo
            this.yellowYardController.eventsToUndo.add(e);
        }
        bool ectoSave = this.stats.ectoBiologyStarted;
        reinit();
        //use seeds the same was as original session and also make DAMN sure the players/guardians are fresh.
        curSessionGlobalVar.makePlayers();
        curSessionGlobalVar.randomizeEntryOrder();
        curSessionGlobalVar.makeGuardians(); //after entry order established
        this.stats.ectoBiologyStarted = ectoSave;
        this.stats.scratched = true;
        this.switchPlayersForScratch();


        SimController.instance.restartSession(); //in controller
    }

    Session initializeCombinedSession() {
        if(this.stats.rocksFell) return null; //can't combo is skaia doesn't exist.
        this.aliensClonedOnArrival = <Player>[]; //PROBABLY want to do this.
        List<Player> living = findLivingPlayers(this.players);
        //nobody is the leader anymore.
        Session newSession = new Session(this.rand.nextInt()); //Math.seed);  //this is a real session that could have gone on without these new players.
        newSession
            ..currentSceneNum = this.currentSceneNum
            ..afterLife = this.afterLife //afterlife carries over.
            ..stats.dreamBubbleAfterlife = this.stats.dreamBubbleAfterlife //this, too
            ..reinit()
            ..makePlayers()
            ..randomizeEntryOrder()
            ..makeGuardians();
        if (living.length + newSession.players.length > 12) {
            ////print("New session " + newSession.session_id +" cannot support living players. Already has " + newSession.players.length + " and would need to add: " + living.length);
           if(! mutator.spaceField) return null; //their child session is not able to support them  (space says 'fuck this noise we doing it')
        }
        //	//print("about to add: " + living.length + " aliens to new session.");
        ////print(getPlayersTitles(living));
        addAliensToSession(newSession, this.players); //used to only bring players, but that broke shipping. shipping is clearly paramount to Skaia, because everything fucking crashes if shipping is compromised.

        this.stats.hadCombinedSession = true;
        newSession.parentSession = this;
        Scene.createScenesForSession(newSession);
        ////print("Session: " + this.session_id + " has made child universe: " + newSession.session_id + " child has this long till reckoning: " + newSession.timeTillReckoning);
        return newSession;
    }

    Player getVersionOfPlayerFromThisSession(Player player) {
        //can double up on classes or aspects if it's a combo session. god. why are their combo sessions?
        for (num i = 0; i < this.players.length; i++) {
            Player p = this.players[i];
            if (p.class_name == player.class_name && p.aspect == player.aspect) {
                return p; //yeah, technically there COULD be two players with the same claspect in a combo session, but i have ceased caring.
            }
        }
        //print("Error finding session's: ${player.title()}");
        return null;
    }

    void reinit() {
        GameEntity.resetNextIdTo(stats.initialGameEntityId);
        resetAvailableClasspects();
        //Math.seed = this.session_id; //if session is reset,
        this.rand.setSeed(this.session_id);
        ////print("reinit with seed: "  + Math.seed);
        this.timeTillReckoning = this.rand.nextIntRange(10, 30); //rand.nextIntRange(10,30);
        this.sessionType = this.rand.nextDouble(); //rand.nextDouble();
        this.available_scenes = <Scene>[]; //need a fresh slate because UpdateShippingGrid has MEMORY unlike all other scenes.
        Scene.createScenesForSession(this);
        //curSessionGlobalVar.available_scenes = curSessionGlobalVar.scenes.slice(0);
        //curSessionGlobalVar.doomedTimeline = false;
        this.stats.doomedTimeline = false;
        this.setUpBosses();
        this.reckoningStarted = false;
        this.importantEvents = <ImportantEvent>[];
        this.stats.rocksFell = false; //sessions where rocks fell screw over their scratched and yarded iterations, dunkass
        this.doomedTimelineReasons = <String>[];
        this.stats.ectoBiologyStarted = false;
    }



    void makePlayers() {
        this.players = <Player>[];
        resetAvailableClasspects();
        int numPlayers = this.rand.nextIntRange(2, 12); //rand.nextIntRange(2,12);
        this.players.add(randomSpacePlayer(this));
        this.players.add(randomTimePlayer(this));

        for (int i = 2; i < numPlayers; i++) {
            this.players.add(randomPlayer(this));
        }

        for (num j = 0; j < this.players.length; j++) {
            Player p = this.players[j];
            p.generateRelationships(this.players);
        }

        Relationship.decideInitialQuadrants(rand, this.players);

        //this.hardStrength = 500 + 20 * this.players.length;

        Sprite weakest = Stats.POWER.min(this.players.map((Player p) => p.sprite));
        double weakpower = weakest.getStat(Stats.POWER) / Stats.POWER.coefficient;
        this.hardStrength = (100 + this.players.length * (85 + weakpower)) * Stats.POWER.coefficient;
    }

    String convertPlayerNumberToWords() {
        //alien players don't count
        List<Player> ps = findPlayersFromSessionWithId(this.players, this.session_id);
        if (ps.isEmpty) {
            ps = this.players;
        }
        int length = ps.length;
        if (length == 2) {
            return "TWO";
        } else if (length == 3) {
            return "THREE";
        } else if (length == 4) {
            return "FOUR";
        } else if (length == 5) {
            return "FIVE";
        } else if (length == 6) {
            return "SIX";
        } else if (length == 7) {
            return "SEVEN";
        } else if (length == 8) {
            return "EIGHT";
        } else if (length == 9) {
            return "NINE";
        } else if (length == 10) {
            return "TEN";
        } else if (length == 11) {
            return "ELEVEN";
        } else if (length == 12) {
            return "TWELVE";
        } else {
            return "???";
        }
    }

    void makeGuardians() {
        ////print("Making guardians");
        resetAvailableClasspects();
        //guardians have to pick from existing classes.
        available_classes_guardians = SBURBClassManager.playersToClasses(players);

        List<Player> guardians = <Player>[];
        for (num i = 0; i < this.players.length; i++) {
            Player player = this.players[i];
            player.makeGuardian();
            guardians.add(player.guardian);
        }

        for (num j = 0; j < this.players.length; j++) {
            Player g = this.players[j].guardian;
            g.generateRelationships(guardians);
        }
        Relationship.decideInitialQuadrants(rand, guardians);
    }

    void randomizeEntryOrder() {
        this.players = shuffle(this.rand, this.players);
        this.players[0].leader = true;
    }

    void switchPlayersForScratch() {
        //var tmp = curSessionGlobalVar.players;
        //curSessionGlobalVar.players = curSessionGlobalVar.guardians;
        //curSessionGlobalVar.guardians = tmp;
        List<Player> nativePlayers = findPlayersFromSessionWithId(this.players, this.session_id);
        ////print(nativePlayers);
        List<Player> guardians = getGuardiansForPlayers(nativePlayers);
        this.players = guardians;
    }

    String getSessionType() {
        if (this.sessionType > .6) {
            return "Human";
        } else if (this.sessionType > .3) {
            return "Troll";
        }
        return "Mixed";
    }

    void setUpBosses() {
        //queen and king handle their jewlery
        npcHandler.spawnQueen();
        npcHandler.spawnKing();
        npcHandler.spawnJack();
        npcHandler.spawnDemocraticArmy();
    }

    @override
    String toString() {
        return session_id.toString();
    }

    Element newScene(String callingScene, [overRideVoid = false]) {
        this.currentSceneNum ++;
        String div;
        String lightBS = "";
        if(mutator.lightField) lightBS = "Scene ID: ${this.currentSceneNum} Name: ${callingScene}  Session Health: ${sessionHealth}  TimeTillReckoning: ${timeTillReckoning} Last Rand: ${rand.spawn().nextInt()}";
        if (this.sbahj) {
            div = "<div class = 'scene' id='scene${this.currentSceneNum}' style='";
            div = "${div}background-color: #00ff00;";
            div = "${div}font-family: Comic Sans MS, cursive, sans-serif;";
            //querySelector("#scene"+this.currentSceneNum).css("background-color", "#00ff00");
            int reallyRand = getRandomIntNoSeed(1, 10);
            for (int i = 0; i < reallyRand; i++) {
                int indexOfTerribleCSS = getRandomIntNoSeed(0, terribleCSSOptions.length - 1);
                List<String> tin = terribleCSSOptions[indexOfTerribleCSS];
                if (tin[1] == "????") {
                    tin[1] = "${getRandomIntNoSeed(1, 100)}%";
                }
                div = "$div${tin[0]}${tin[1]};";
            }
            div = "$div' >";
            if (ouija == true) div = "$div<img class = 'pen15' src = 'images/pen15_bg1.png'>"; //can't forget the dicks;
            div = "$div $lightBS</div>";
        } else if (ouija == true) {
            int trueRandom = getRandomIntNoSeed(1, 4);
            div = "<div class = 'scene' id='scene${this.currentSceneNum}'>";
            div = "$div<img class = 'pen15' src = 'images/pen15_bg$trueRandom.png'>";
            div = "$div $lightBS</div>";
        } else {
            div = "<div class = 'scene' id='scene${this.currentSceneNum}'>$lightBS</div>";
        }

        //instead of appending you're replacing. Void4 is SERIOUS about you not getting to see.
        if(mutator.voidField && !overRideVoid) {
            Element voidDiv = querySelector("#voidStory");
            if(voidDiv == null) {
                doNotRender = true;
                numScenes = 0; //since we're lying to AB anyway, use this to keep track of how many scenes we skipped due to void
                doNotFetchXml = true;
                appendHtml(querySelector("#story"), "<div id = 'voidStory'></div>");
                voidDiv = querySelector("#voidStory");
            }
            voidDiv.setInnerHtml("${"<br>"*numScenes}$div");//one br for each skipped scene
            return querySelector("#scene${this.currentSceneNum}");
        }else if(overRideVoid) {
            logger.info("am i setting do not render to false?");
            //doNotRender = false; //this fucks AB up. don't do it. but at least they'll see the text.
        }

        appendHtml(querySelector("#story"), div);
        return querySelector("#scene${this.currentSceneNum}");
    }

    List<Session> getLineage() {
        //print("Getting lineage for session: $session_id");
        if (this.parentSession != null) {
            List<Session> tmp = this.parentSession.getLineage();
            tmp.add(this);
            return tmp;
        }
        return <Session>[this];
    }

    SessionSummary generateSummary() {
        return SessionSummary.makeSummaryForSession(this);
    }

}

//save a copy of the alien (in case of yellow yard)
void addAliensToSession(Session newSession, List<Player> aliens) {
    ////print("in method, adding aliens to session");
    for (num i = 0; i < aliens.length; i++) {
        Player survivor = aliens[i];
        survivor.land = null;
        survivor.dreamSelf = false;
        survivor.godDestiny = false;
        survivor.leader = false;
    }
    //save a copy of the alien players in case this session has time shenanigans happen

    for (num i = 0; i < aliens.length; i++) {
        Player survivor = aliens[i];
        newSession.aliensClonedOnArrival.add(clonePlayer(survivor, newSession, false));
    }
    //don't want relationships to still be about original players
    for (num i = 0; i < newSession.aliensClonedOnArrival.length; i++) {
        Player clone = newSession.aliensClonedOnArrival[i];
        Relationship.transferFeelingsToClones(clone, newSession.aliensClonedOnArrival);
    }
    ////print("generated relationships between clones");
    //generate relationships AFTER saving a backup of hte player.
    //want clones to only know about other clones. not players.
    for (num i = 0; i < aliens.length; i++) {
        Player survivor = aliens[i];
        ////print(survivor.title() + " generating relationship with new players ")
        survivor.generateRelationships(newSession.players); //don't need to regenerate relationship with your old friends
    }


    for (int j = 0; j < newSession.players.length; j++) {
        Player player = newSession.players[j];
        player.generateRelationships(aliens);
    }

    for (num i = 0; i < aliens.length; i++) {
        for (int j = 0; j < newSession.players.length; j++) {
            Player player = newSession.players[j];
            Player survivor = aliens[i];
            //survivors have been talking to players for a very long time, because time has no meaning between univereses.
            Relationship r1 = survivor.getRelationshipWith(player);
            Relationship r2 = player.getRelationshipWith(survivor);
            r1.moreOfSame();
            r1.moreOfSame();
            //been longer from player perspective
            r2.moreOfSame();
            r2.moreOfSame();
            r2.moreOfSame();
            r2.moreOfSame();
        }
    }

    newSession.players.addAll(aliens);
}
