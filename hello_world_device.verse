
using { /Fortnite.com/AI }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Fortnite.com/Animation/PlayAnimation }
using { /Verse.org/Assets }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Verse.org/Simulation/Tags }
# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.
#makeshift way to keep track of all alive npc's outside of creative_device
var TempPlayerPersistance: weak_map(player, NpcPositions) = map{}

NPCWithCritPoints := class<concrete>:
    @editable Name:string = "NPC"
    @editable Spawner: npc_spawner_device = npc_spawner_device{}
    @editable PlayerIndex:int = 0

NPC_Commands := class<final><persistable>:
    Command: string = "GoTo:25.8,850.55,0.0"

NpcPositions := class<final><persistable>:
    CommandMap:[string]NPC_Commands

# A Verse-authored creative device that can be placed in a level
Main_Device<public> := class(creative_device):
    @editable SpawnerList: []NPCWithCritPoints = array{}
    @editable LinearRaycastAsset: creative_prop_asset = DefaultCreativePropAsset
    @editable DebugAsset : creative_prop_asset = DefaultCreativePropAsset
    @editable LeftClick: input_trigger_device = input_trigger_device{}
    var AliveNpcs : [fort_character]string = map{}

    var SelectedNpc:?fort_character = false

    var MaybeActiveRP: ?RaycastProp = false

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        LeftClick.PressedEvent.Subscribe(HandleLeftClick)
        for(Player:GetPlayspace().GetPlayers()):
            if(set TempPlayerPersistance[Player] = NpcPositions{CommandMap:=map{}}){}
            if(FC:=Player.GetFortCharacter[]):
                FC.Hide()
                RP := SpawnRaycastProp(LinearRaycastAsset, FC.GetTransform().Translation)
                set MaybeActiveRP = RP
                if(ARP:= RP?):
                    spawn. MoveRaycastAround(ARP, Player)

        for(SpawnerItem:SpawnerList):
            if(Player:=GetPlayspace().GetPlayers()[SpawnerItem.PlayerIndex]):
                SpawnerItem.Spawner.SpawnedEvent.Subscribe(NPC_spawn{Device:=Self, Player:=Player, LocationToGo:= vector3{X:=100.0, Y:=100.0, Z:=0.0}}.HandlerFunction)
                SpawnerItem.Spawner.EliminatedEvent.Subscribe(NPC_Despawn{Device:=Self, Name:=SpawnerItem.Name}.HandlerFunction)


    MoveRaycastAround(RP:RaycastProp, Player:agent)<suspends>:void=
        if(FC:= Player.GetFortCharacter[]):   
            Debug:= SpawnTarget(vector3{X:=10.0, Y:=10.0, Z:=10.0}, DebugAsset)
            loop:
                V:=CalculatePoint(Player, 250.0, "Forward")
                RP.Parent.MoveTo(V, FC.GetViewRotation(), 0.1)
                spawn. Debug.MoveTo(RP.HitLocationProp.GetTransform().Translation,IdentityRotation(),0.1)
                

    AddNPC(NPC:agent, Player:player, LocationToGo:vector3)<suspends>:void=
        Sleep(0.1)
        if(NPCFC:= NPC.GetFortCharacter[]):
            SpawnLocation := NPCFC.GetTransform().Translation
            LocationKey:= "{SpawnLocation.X},{SpawnLocation.Y}"
            if(set AliveNpcs[NPCFC] =LocationKey ){}
            if(Positions := TempPlayerPersistance[Player].CommandMap):
                var NewPositions : [string]NPC_Commands = Positions
                if(set NewPositions[LocationKey] = NPC_Commands{}){}
                if(set TempPlayerPersistance[Player] = NpcPositions{CommandMap:=NewPositions}){}
                if(NPCFC.TeleportTo[LocationToGo, NPCFC.GetTransform().Rotation]){}


    RemoveNPC(SpawnLocation:string, Res:device_ai_interaction_result):void=
        if(Target:=Res.Target?):
            if(FC:= fort_character[Target]):
                if(CorrectArr:= AliveNpcs[SpawnLocation]):
                    var NewMap : [fort_character]string  = map{}
                    for(MFC->Key: AliveNpcs):
                        if(Key<>SpawnLocation):
                            if(set NewMap[MFC] = Key){}
                    set AliveNpcs = NewMap

    HandleLeftClick(Agent:agent):void=
        if(ActiveRP:=MaybeActiveRP?):
            ActiveLocation := ActiveRP.HitLocationProp.GetTransform().Translation

            if(ASelectedNPC:=SelectedNpc? ):
                Print("selected npc")
                CommandString := "GoTo:{ActiveLocation.X},{ActiveLocation.Y},{ActiveLocation.Z}"
                if(Player:= player[Agent]):
                    if(Positions := TempPlayerPersistance[Player].CommandMap):
                        var NewPositions : [string]NPC_Commands = Positions
                        if(set NewPositions[AliveNpcs[ASelectedNPC]] = NPC_Commands{Command:=CommandString}){}
                        if(set TempPlayerPersistance[Player] = NpcPositions{CommandMap:=NewPositions}){}
                        set SelectedNpc = false
            else:
                Print("no selected npc")
                var PossibleNPCs :[]fort_character = array{}
                for(FC->Key: AliveNpcs):
                    set PossibleNPCs+= array{FC}
                MaybeFoundNpc := ActiveLocation.GetClosestFCInRange(PossibleNPCs, ?MaxRange:= 300.0)(0)
                set SelectedNpc = MaybeFoundNpc
                
                




NPC_spawn := class() {
    Device : Main_Device   <#YOU MUST CHANGE "main" TO YOUR VERSE DEVICE NAME#>
    
    Player:player
    LocationToGo:vector3
    HandlerFunction(Agent:agent) : void = {
        spawn.  Device.AddNPC(Agent, Player, LocationToGo)
     
    }
}
        
NPC_Despawn := class() {
    Device : Main_Device   <#YOU MUST CHANGE "main" TO YOUR VERSE DEVICE NAME#>
    
    Name:string
    HandlerFunction(Res:device_ai_interaction_result) : void = {
        Device.RemoveNPC(Name, Res)
    }
}

