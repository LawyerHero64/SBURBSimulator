import "../Feature.dart";
import "../../SBURBSim.dart";
class AmbianceFeature extends Feature {
    ///flavor text, "you don't get it, my land feels really $feelsLike"  creepy, unsettling, vs peaceful, calm,

    AmbianceFeature(String simpleDesc, [int quality = 0]):super(simpleDesc, quality);

    //TODO when this is called "normally" each player can react to a different feature of the land. so only one player at a time

    static String randomFlavorText(Random rand, String specific, int quality, Player p) {
        if(quality>0) return AmbianceFeature.randomGoodFlavorText(rand, specific, p);
        if(quality<0) return AmbianceFeature.randomBadFlavorText(rand, specific, p);
        if(quality==0) return AmbianceFeature.randomNeutralFlavorText(rand, specific, p);
    }

    //passed in specific can have 'ands' in the middle
    static String randomNeutralFlavorText(Random rand, String specific, Player p) {
        WeightedList<String> possibilities = new WeightedList<String>();
        possibilities.add("");
        possibilities.add("It feels $specific.",.3);
        return rand.pickFrom(possibilities);
    }

    //passed in specific can have 'ands' in the middle
    static String randomGoodFlavorText(Random rand, String specific, Player p) {
        WeightedList<String> possibilities = new WeightedList<String>();
        possibilities.add("The ${p.htmlTitleBasic()} is reassured by how $specific it feels.");
        possibilities.add("The ${p.htmlTitleBasic()} feels right at home with how $specific it feels here. ", 0.5);
        possibilities.add("It feels $specific.  It's pretty great, actually. ");
        return rand.pickFrom(possibilities);
    }

    //passed in specific can have 'ands' in the middle
    static String randomBadFlavorText(Random rand, String specific, Player p) {
        WeightedList<String> possibilities = new WeightedList<String>();
        possibilities.add("The ${p.htmlTitleBasic()} is getting tired of how $specific it feels.", 0.5);
        possibilities.add("It's a little unsettling how $specific it feels. ");
        possibilities.add("The ${p.htmlTitleBasic()} is unnerved with how $specific it feels here.");

        return rand.pickFrom(possibilities);
    }
}