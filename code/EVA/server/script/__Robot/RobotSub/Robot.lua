local Robot = class("Robot")

function Robot:ctor()
	
    self.Data               = RobotData:new();
    self.Fsm                = FSMRobot:new();
    self.Fsm:Init(self);
    
    self.Net        = bin_types.LuaCallbackClient.NewInstance("tcp");

end

function Robot:Init( net_handle )
    self.Net:SetHandle(net_handle);
end

function Robot:Update()
    self.Net:Update();

    self.Fsm:TickUpdate();

    if self.GameFsm~=nil then
        self.GameFsm:TickUpdate();
        self.Game:Update();

    end
end

function Robot:GetHandle()
    return self.Net:GetHandle();
end

function Robot:Connected()
    return self.Net:Connected();
end

-- ??ʼ??Ϸ?߼?????
function Robot:StartGameTest()
    if self.Data.Game == "RM_DDZ"	then
        self.Game                   = RobotGameDdz:new();
        self.Game.Robot             = self;
        self.GameFsm                = FSMDdz:new();
        self.GameFsm:Init(self);
    end
end

function Robot:PrintTable( tbl )
    RobotMgr:PrintTable(tbl, self.Data.UID);
end
    
function Robot:Print( str )
    RobotMgr:Print(str, self.Data.UID);
end

function Robot:Login()
    
    local login_url     = "http://127.0.0.1/www/login/login_test.php";
    local login_params  = "?Channel=REG&GameType="..self.Data.Game.."&User="..self.Data.User.."&AppName=WX_5E8A";
    local http_res      = Net.HttpGet(login_url..login_params);
    
    if http_res==nil or #http_res<20 then
        nlwarning("http login error")
        return
    end
    
    local http_tb       = Json2Table(http_res);

    self:PrintTable(http_tb)

    self.Net:Connect("127.0.0.1:9999");

    if self.Net:Connected() then

        local proto_msg = {
            UID         = http_tb.UID,
            Channel     = "REG",
            RoomType    = "RM_DDZ",
            AppName     = "WX_5E8A",
            User        = self.Data.User,
            NonceStr    = http_tb.NonceStr,
            Timestamp   = http_tb.Timestamp,
            Token       = http_tb.Token,
        }

        self:Send( "LOGIN", "PB.MsgLogin", proto_msg )

        self:Print("Login :"..self.Data.User);
        return true;
    else
        nlwarning("Connect Error :"..self.Data.User);
    end

    return false;
end

function Robot:HeartBeat()
    local msgout    = CMessage("HB");
    self.Net:Send( msgout );
end

function Robot:Send( msgname, proto_type, proto_msg )
    local msg   = CMessage(msgname);
    if proto_type~=nil then
        local code  = protobuf.encode(proto_type, proto_msg);
        msg:wstring(code);
    end
    self.Net:Send( msg );
end



function Robot:cbSyncPlayerInfo( msgin )
    local player_info = msgin:rpb("PB.MsgPlayerInfo");

    if player_info==nil then
        nlwarning("player_info==nil !!!!!!!!!");
        return;
    end
    
    self:Print("Robot:cbSyncPlayerInfo");
    self:PrintTable(player_info);
    
    self.Data.UID   = player_info.UID;
    
    
end


return Robot;
