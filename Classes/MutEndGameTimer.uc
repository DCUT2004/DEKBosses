class MutEndGameTimer extends Mutator
	config(DEKBossMonsters);
	
var config int EndTimer;

//Called by the bosses in Died()
function Timer()
{
	if (Level.Game != None && Invasion(Level.Game) != None)
	{
		Invasion(Level.Game).SetTimer(1, True);
	}
	SetTimer(0, False);
}
	

defaultproperties
{
	 EndTimer=20		//How many seconds before the game officially declares as end
     bAddToServerPackages=True
     GroupName="EndGameTimer"
     FriendlyName="End Game Timer"
     Description="Provides a small amount of time after defeating a boss so players can purchase materials."
     bAlwaysRelevant=True
}
