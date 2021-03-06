import "dart:html";
import "../../SBURBSim.dart";


///completely different intro from a regular session, none of that boring "dialogue" that regular sessions start with.
///
class DeadIntro extends Scene {

    DeadIntro(Session session) : super(session);

    @override
    void renderContent(Element div) {
        Player player = session.players[0];
        (session as DeadSession).makeDeadLand();
        String divID = "deadIntro${session.players[0].id}";
        String narration = "A wave of destruction heralds the arrival of the ${player.htmlTitle()}. They are the only Player. SBURB was never meant to be single player, and they have activated the secret 'Dead Session' mode as a punishment. Or is it a reward?  ";
        narration += " <Br><br>Skaia is black and lifeless. ";
        narration += "What can they even do now? Is there even a way to win? ";
        narration += " <Br><Br>They stare hopelessly at what was their former planet, now transformed into the ${player.landFuture.name}. ";
        narration += "<HR><h2>HEY, JR HERE. THIS IS A WORK IN PROGRESS THAT IS <B>GOING</B> TO CRASH. DEAL WITH IT. I'M STILL CODING IT.</h2><hr>";
        narration += " ${player.landFuture.randomFlavorText(session.rand, player)} ";
        String html = "<canvas id='${divID}' width='${canvasWidth.toString()}' height='${canvasHeight.toString()}'>  </canvas><br><Br>$narration";
        appendHtml(div, html);
        Drawing.drawSinglePlayer(querySelector("#${divID}"), player);

    }

    @override
    bool trigger(List<Player> playerList) {
        return true;
    }
}