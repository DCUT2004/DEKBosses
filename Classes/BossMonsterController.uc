class BossMonsterController extends DCMonsterController;

function PostBeginPlay()
{
	Super(MonsterController).PostBeginPlay();
	StatusManager = Spawn(Class'StatusEffectInventory_Player');
}
	

defaultproperties
{
}
