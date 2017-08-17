local config = require("config")
local ball = require("ball")
local objtype = require("objtype")
local M = {}

local battleUser = {}
battleUser.__index = battleUser

function M.new(player,userID)
	local o = {}
	o = setmetatable(o,battleUser)
	o.color = math.random(1,#config.colors)
	o.balls = {}
	o.ballCount = 0
	if player then
		o.player = player
		player.battleUser = o
	end	
	o.userID = userID
	o.stop = true
	return o
end

function battleUser:Relive()
	local r = math.ceil(config.Score2R(config.initScore))
	local pos = {}
	local mapWidth = self.battle.mapBorder.topRight.x - self.battle.mapBorder.bottomLeft.x
	local mapHeight = self.battle.mapBorder.topRight.y - self.battle.mapBorder.bottomLeft.y	
	pos.x = math.random(r, mapWidth - r)
	pos.y = math.random(r, mapHeight - r)
	local ballID = self.battle:GetBallID()

	local newBall = ball.new(ballID,self,objtype.ball,pos,config.initScore,self.color)
	if newBall then
		local t = {
			cmd = "BeginSee",
			timestamp = self.battle.tickCount,
			balls = {}
		}
		newBall:PackOnBeginSee(t.balls)
		self.battle:Broadcast(t)	
	end
end

function battleUser:Update(elapse)
	for k,v in pairs(self.balls) do
		v:Update(elapse)
		self.battle.colMgr:CheckCollision(v)	
	end
end

function battleUser:PackBallsOnBeginSee(t)
	for k,v in pairs(self.balls) do
		v:PackOnBeginSee(t)
	end
end

function battleUser:Move(msg)
	self.stop = nil
	if self.ballCount == 1 then
		for k,v in pairs(self.balls) do
			v:Move(msg.dir)
		end
	else
		self.reqDirection = msg.dir
	end	
end

function battleUser:Stop(msg)
	self.reqDirection = nil
	self.stop = true
	for k,v in pairs(self.balls) do
		v:Stop()
	end
end

function battleUser:Send2Client(msg)
	if self.player then
		self.player:Send2Client(msg)
	end
end

function battleUser:OnBallDead(ball)
	if ball.owner == self then
		self.balls[ball.id] = nil
		self.ballCount = self.ballCount - 1
	end
end

--吐孢子
function battleUser:Spit()
	for k,v in pairs(self.balls) do
		v:Spit()
	end
end

--分裂
function battleUser:Split()

end

function battleUser:UpdateBallMovement()
	if self.ballCount == 0 or nil == self.reqDirection then
		return
	else
		--先计算小球的几何重心
		local cx = 0
		local cy = 0
		for k,v in pairs(self.balls) do
			cx = cx + v.pos.x
			cy = cy + v.pos.y
		end
		local centralPos = {x = cx/self.ballCount, y = cy / self.ballCount}
		local maxDis = 0
		for k,v in pairs(self.balls) do
			local dis = util.point2D.Distance(v.pos,centralPos) + v.r
			if dis > maxDis then
				maxDis = dis
			end
		end
		local forwordDis = maxDis + 300
		local forwordPoint = util.point2D.moveto(centralPos,forwordDis)
		for k,v in pairs(self.balls) do
			local vv = util.vector2D.new(forwordPoint.x - v.pos.x , forwordPoint.y - v.pos.y)
			v:Move(vv:getDirAngle())
		end
	end
end

return M