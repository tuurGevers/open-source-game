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
 
# Getting started: https://www.epicgames.com/fortnite/en-US/creative/docs/uefn/Verse/onboarding-guide-to-programming-with-verse-in-unreal-editor-for-fortnite

# A Verse-authored NPC Behavior that can be used within an NPC Character Definition or an NPC Spawner device's NPC Behavior Script Override.
new_npc_behavior_basic<public> := class(npc_behavior):
    @editable PlayerIndex: int = 0
    var SpawnLocation:vector3 = vector3{}
    var LocationKey:string = ""
    var IsAlive:logic=true
    var CurrentCommand:string = ""
    var CommandIndex:int = 0

    MinBound :vector3= vector3{X:=-12736.0, Y:=7080.0, Z:=52.0} 
    MaxBound :vector3= vector3{X:=-3468.0, Y:=12708.0, Z:=52.0}
    
    # This function runs when the NPC is spawned in the world and ready to follow a behavior.
    OnBegin<override>()<suspends>:void=
        if(Agent:=GetAgent[], NPC:=Agent.GetFortCharacter[]):
            if(NPC.TeleportTo[GetRandomVector3(MinBound, MaxBound), IdentityRotation()]):
                Sleep(0.01)
                set SpawnLocation=NPC.GetTransform().Translation
                set LocationKey="{SpawnLocation.X},{SpawnLocation.Y}"
        # TODO: Replace this with your code

        Sleep(2.0)
        loop:
            Sleep(1.0)
            if(IsAlive = false):
                break
            if(Commands:= TempPlayerPersistance[GetPlayers()[PlayerIndex]].CommandMap):
                for(Key->Value: Commands):
                    if(Key = LocationKey):
                        if(not CurrentCommand = Value.Command):
                            Print("found command")
                            if(Value.Command.Split(":")[0] = "GoTo"):
                                set CommandIndex +=1 
                                Print("GOTO")
                                spawn. GoTo(Value.Command)
                            set CurrentCommand = Value.Command


                      

    GoTo(CommanString:string)<suspends>:void=
        if(Agent:=GetAgent[], NPC:=Agent.GetFortCharacter[]):
            if(ArgString:= CommanString.Split(":")[1]):
                Print("{ArgString}")
                Args := ArgString.Split(",")
                if(
                    X:= Args[0].ToFloat(),
                    Y:= Args[1].ToFloat(),
                    Z:= Args[2].ToFloat()
                ):
                    Res:= race:
                        NPC.NavigateToLocation(vector3{X:=X,Y:=Y,Z:=Z}, 10.0)
                        ShouldCancelCommand(CommandIndex)
                    if(Res = -1 ):
                        if(Nav:= NPC.GetNavigatable[]):
                            Nav.StopNavigation()
                    Print("{X},{Y},{Z}")

    ShouldCancelCommand(commandIndex:int)<suspends>:int=
        loop:
            Sleep(0.2)
            if(not commandIndex = commandIndex):
                break
        return -1


    # This function runs when the NPC is despawned or eliminated from the world.
    OnEnd<override>():void=
        set IsAlive = false
        # TODO: Replace this with your code
        Print("Goodbye, NPC!")