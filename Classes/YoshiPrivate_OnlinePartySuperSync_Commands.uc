//EpicYoshiMaster's super secret commands for Online Party Super Syncing
//If you're reading this message then you either went through a whole lot of effort or just know that the editor files are like plain text
//So congratulations, if you actually manage to do anything with this I'll be surprised but don't do anything sneaky

                    
                    
//              ))))))     
//             )::::::))   
//              ):::::::)) 
//               )):::::::)
//                 )::::::)
//      ::::::      ):::::)
//      ::::::      ):::::)
//      ::::::      ):::::)
//                  ):::::)
//                  ):::::)
//                  ):::::)
//      ::::::     )::::::)
//      ::::::   )):::::::)
//      ::::::  ):::::::)) 
//             )::::::)    
//              ))))))     


class YoshiPrivate_OnlinePartySuperSync_Commands extends Object;

struct OPSSTeam {
    var string TeamName;
    var const string TeamCode;
    var LinearColor TeamColor;
};

const OPSSItem = 'eUCAogBeFzoPvsVsPiSD';

var const array<OPSSTeam> Teams;

defaultproperties
{
    Teams.Add((TeamName = "Red", TeamCode = "XGO548hTNi", TeamColor = (R = 1, G = 0.01, B = 0.01, A = 3))); //Red
    Teams.Add((TeamName = "Green", TeamCode = "q8Re5U4wv5", TeamColor = (R = 0.01, G = 1, B = 0.01, A = 3))); //Green
    Teams.Add((TeamName = "Blue", TeamCode = "QssVGb6kKa", TeamColor = (R = 0.00367, G = 0.0665, B = 1, A = 3))); //Blue <---- Best Team
    Teams.Add((TeamName = "Yellow", TeamCode = "wJAY273RTt", TeamColor = (R = 1, G = 1, B = 0.01, A = 3))); //Yellow

    Teams.Add((TeamName = "Orange", TeamCode = "Ze5we6b634", TeamColor = (R = 1, G = 0.0811, B = 0, A = 3))); //Orange
    Teams.Add((TeamName = "Pink", TeamCode = "eb4XxMWcnq", TeamColor = (R = 1, G = 0.0701, B = 1, A = 3))); //Pink
    Teams.Add((TeamName = "Purple", TeamCode = "TBW9HLv4dw", TeamColor = (R = 0.17, G = 0, B = 1, A = 3))); //Purple
    Teams.Add((TeamName = "White", TeamCode = "KusTjg94wM", TeamColor = (R = 1, G = 1, B = 1, A = 3))); //White

}
