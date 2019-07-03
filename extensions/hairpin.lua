--[[
	太阳神三国杀武将扩展包·金陵十二钗
	适用版本：V2 - 愚人版（版本号：20150401）清明补丁（版本号：20150405）
	武将总数：12
	武将一览：
		1、林黛玉（葬花、还泪）
		2、薛宝钗（锁玉、空闺）
		3、贾元春（省亲、宫恨）
		4、贾探春（结社、变革）
		5、史湘云（醉石、性情）
		6、妙玉（梅雪、劫数）
		7、贾迎春（如木、忍辱）
		8、贾惜春（冷绝、弃世）
		9、王熙凤（弄权、算尽）
		10、贾巧姐（乞巧、交缘）
		11、李纨（稻香、心血）
		12、秦可卿（迷津、托梦）
	所需标记：
		1、@hpHuanLeiMark（“泪”标记，来自技能“还泪”）
		2、@hpXingQinMark（“亲”标记，来自技能“省亲”）
		3、@hpQiShiMark（“弃世”标记，来自技能“弃世”）
		4、@hpQiQiaoMark（“乞巧”标记，来自技能“乞巧”）
]]--
module("extensions.hairpin", package.seeall)
extension = sgs.Package("hairpin", sgs.Package_GeneralPack)
--技能暗将
hpAnJiang = sgs.General(extension, "hpAnJiang", "god", 5, true, true, true)
--翻译信息
sgs.LoadTranslationTable{
	["hairpin"] = "金陵十二钗",
}
--[[****************************************************************
	编号：HPIN - 001
	武将：林黛玉
	称号：情情
	势力：魏
	性别：女
	体力上限：3勾玉
]]--****************************************************************
LinDaiYu = sgs.General(extension, "hpLinDaiYu", "wei", 3, false)
--翻译信息
sgs.LoadTranslationTable{
	["hpLinDaiYu"] = "林黛玉",
	["&hpLinDaiYu"] = "林黛玉",
	["#hpLinDaiYu"] = "情情",
	["designer:hpLinDaiYu"] = "DGAH",
	["cv:hpLinDaiYu"] = "无",
	["illustrator:hpLinDaiYu"] = "网络资源",
	["~hpLinDaiYu"] = "林黛玉 的阵亡台词",
}
--[[
	技能：葬花
	描述：出牌阶段限一次，你可以将一张方块或草花牌置于牌堆底，然后你选择一项：1、令你攻击范围内的一名角色失去1点体力；2、摸两张牌。
]]--
ZangHuaCard = sgs.CreateSkillCard{
	name = "hpZangHuaCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("hpZangHua") --播放配音
		local subcards = self:getSubcards()
		local move = sgs.CardsMoveStruct()
		move.to = nil
		move.to_place = sgs.Player_DrawPile
		move.card_ids = subcards
		move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName())
		room:moveCardsAtomic(move, true)
		local id = room:drawCard()
		local ids = sgs.IntList()
		ids:append(id)
		room:askForGuanxing(source, ids, sgs.Room_GuanxingDownOnly)
		local choices = {}
		local alives = room:getAlivePlayers()
		local victims = sgs.SPlayerList()
		for _,p in sgs.qlist(alives) do
			if source:inMyAttackRange(p) then
				victims:append(p)
			end
		end
		if not victims:isEmpty() then
			table.insert(choices, "lose")
		end
		table.insert(choices, "draw")
		choices = table.concat(choices, "+")
		local choice = room:askForChoice(source, "hpZangHua", choices)
		if choice == "lose" then
			local victim = room:askForPlayerChosen(source, victims, "hpZangHua", "@hpZangHua", false)
			if victim then
				room:loseHp(victim, 1)
			end
		elseif choice == "draw" then
			room:drawCards(source, 2, "hpZangHua")
		end
	end,
}
ZangHua = sgs.CreateViewAsSkill{
	name = "hpZangHua",
	n = 1,
	view_filter = function(self, selected, to_select)
		local suit = to_select:getSuit()
		return suit == sgs.Card_Diamond or suit == sgs.Card_Club
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = ZangHuaCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:isNude() then
			return false
		elseif player:hasUsed("#hpZangHuaCard") then
			return false
		end
		return true
	end,
}
--添加技能
LinDaiYu:addSkill(ZangHua)
--翻译信息
sgs.LoadTranslationTable{
	["hpZangHua"] = "葬花",
	[":hpZangHua"] = "<font color=\"green\"><b>出牌阶段限一次</b></font>，你可以将一张<b>方</b><b>块</b>或<b>草</b><b>花</b>牌置于牌堆底，然后你选择一项：1、令你攻击范围内的一名角色失去1点体力；2、摸两张牌。",
	["@hpZangHua"] = "葬花：请选择将失去体力的角色",
	["hpZangHua:lose"] = "令攻击范围内的一名角色失去1点体力",
	["hpZangHua:draw"] = "摸两张牌",
	["hpzanghua"] = "葬花",
}
--[[
	技能：还泪
	描述：你每受到1点伤害，获得一枚“泪”标记。
		你濒死时，你可以弃置所有的“泪”标记并令一名其他角色摸等量的牌，然后该角色增加1点体力上限并回复1点体力。若如此做，你进行一次判定，若结果为红心【桃】，你回复所有体力，否则你立即死亡。
]]--
HuanLei = sgs.CreateTriggerSkill{
	name = "hpHuanLei",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged, sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			player:gainMark("@hpHuanLeiMark", damage.damage)
		elseif event == sgs.Dying then
			local dying = data:toDying()
			local victim = dying.who
			if victim:objectName() == player:objectName() then
				local count = player:getMark("@hpHuanLeiMark")
				if count > 0 then
					local others = room:getOtherPlayers(player)
					local prompt = string.format("@hpHuanLei:::%d:", count)
					local target = room:askForPlayerChosen(player, others, "hpHuanLei", prompt, true, true)
					if target then
						player:loseAllMarks("@hpHuanLeiMark")
						room:drawCards(target, count, "hpHuanLei")
						local maxhp = target:getMaxHp() + 1
						room:setPlayerProperty(target, "maxhp", sgs.QVariant(maxhp))
						local recover = sgs.RecoverStruct()
						recover.who = player
						recover.recover = 1
						room:recover(target, recover)
						local judge = sgs.JudgeStruct()
						judge.who = player
						judge.reason = "hpHuanLei"
						judge.pattern = "Peach|heart|."
						judge.good = true
						room:judge(judge)
						if judge:isGood() then
							local recover = sgs.RecoverStruct()
							recover.who = player
							recover.recover = player:getMaxHp() - player:getHp()
							room:recover(player, recover)
						else
							room:killPlayer(player)
							return true
						end
					end
				end
			end
		end
		return false
	end,
}
--添加技能
LinDaiYu:addSkill(HuanLei)
--翻译信息
sgs.LoadTranslationTable{
	["hpHuanLei"] = "还泪",
	[":hpHuanLei"] = "你每受到1点伤害，获得一枚“泪”标记。\
你濒死时，你可以弃置所有的“泪”标记并令一名其他角色摸等量的牌，然后该角色增加1点体力上限并回复1点体力。若如此做，你进行一次判定，若结果不红心【桃】，你回复所有体力，否则你立即死亡。",
	["@hpHuanLei"] = "您可以发动“还泪”选择一名其他角色，令其摸 %arg 张牌，然后该角色增加1点体力上限并回复1点体力",
	["@hpHuanLeiMark"] = "泪",
}
--[[****************************************************************
	编号：HPIN - 002
	武将：薛宝钗
	称号：无情
	势力：吴
	性别：女
	体力上限：3勾玉
]]--****************************************************************
XueBaoChai = sgs.General(extension, "hpXueBaoChai", "wu", 3, false)
--翻译信息
sgs.LoadTranslationTable{
	["hpXueBaoChai"] = "薛宝钗",
	["&hpXueBaoChai"] = "薛宝钗",
	["#hpXueBaoChai"] = "无情",
	["designer:hpXueBaoChai"] = "DGAH",
	["cv:hpXueBaoChai"] = "无",
	["illustrator:hpXueBaoChai"] = "网络资源",
	["~hpXueBaoChai"] = "薛宝钗 的阵亡台词",
}
--[[
	技能：锁玉
	描述：一名角色的摸牌阶段开始时，你可以摸一张牌，然后交给其一张牌。若如此做，你不能再次发动“锁玉”直到你的下个回合开始，且该角色摸牌阶段摸牌时少摸一张牌。
]]--
SuoYu = sgs.CreateTriggerSkill{	
	name = "hpSuoYu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.DrawNCards, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Draw then
				local alives = room:getAlivePlayers()
				local prompt = string.format("invoke:%s", player:objectName())
				for _,source in sgs.qlist(alives) do
					if source:hasSkill("hpSuoYu") and source:getMark("hpSuoYuInvoked") == 0 then
						if source:askForSkillInvoke("hpSuoYu", sgs.QVariant(prompt)) then
							room:broadcastSkillInvoke("hpSuoYu") --播放配音
							room:notifySkillInvoked(source, "hpSuoYu") --显示技能发动
							room:addPlayerMark(player, "hpSuoYuTarget", 1)
							room:drawCards(source, 1, "hpSuoYu")
							if not source:isNude() then
								local hint = string.format("@hpSuoYu:%s:", player:objectName())
								local ai_data = sgs.QVariant()
								ai_data:setValue(player)
								local card = room:askForCard(
									source, "..!", hint, ai_data, sgs.Card_MethodNone, player, false, "hpSuoYu", false
								)
								if not card then
									local cards = source:getCards("he")
									local count = cards:length()
									local index = math.random(1, count) - 1
									card = cards:at(index)
								end
								room:obtainCard(player, card, false)
							end
							room:setPlayerMark(source, "hpSuoYuInvoked", 1)
						end
					end
				end
			elseif phase == sgs.Player_Start then
				if player:getMark("hpSuoYuInvoked") > 0 then
					room:setPlayerMark(player, "hpSuoYuInvoked", 0)
				end
			end
		elseif event == sgs.DrawNCards then
			local count = player:getMark("hpSuoYuTarget")
			if count > 0 then
				local msg = sgs.LogMessage()
				msg.type = "#hpSuoYu"
				msg.from = player
				msg.arg = "hpSuoYu"
				msg.arg2 = count
				room:sendLog(msg) --发送提示信息
				local n = data:toInt() - count
				n = math.max( 0, n )
				data:setValue(n)
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Draw then
				room:setPlayerMark(player, "hpSuoYuTarget", 0)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
--添加技能
XueBaoChai:addSkill(SuoYu)
--翻译信息
sgs.LoadTranslationTable{
	["hpSuoYu"] = "锁玉",
	[":hpSuoYu"] = "一名角色的摸牌阶段开始时，你可以摸一张牌，然后交给其一张牌。若如此做，“锁玉”技能无效直到你的下个回合开始，且该角色摸牌阶段摸牌时少摸一张牌。",
	["hpSuoYu:invoke"] = "您想对 %src 发动技能“锁玉”吗？",
	["@hpSuoYu"] = "锁玉：请交给 %src 一张牌（包括装备）",
	["#hpSuoYu"] = "受技能“%arg”影响，%from 本阶段少摸 %arg2 张牌",
}
--[[
	技能：空闺
	描述：当你需要使用或打出一张基本牌或非延时性锦囊牌时，若你没有手牌，你可以视为使用或打出了此牌。每名角色的回合限一次。
]]--
local cardtypes = {
	["standard_cards"] = {
		"slash", "jink", "peach", "nullification",
		"god_salvation", "amazing_grace", "savage_assault", "archery_attack",
		"dismantlement", "snatch", "collateral", "duel", "ex_nihilo",
	},
	["maneuvering"] = {
		"fire_slash", "thunder_slash", "analeptic",
		"fire_attack", "iron_chain",
	},
	["New1v1Card"] = {
		"drowning",
	},
}
local banPackages = false
local _RESPONSE = sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
local _RES_USE = sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
local _USE = sgs.CardUseStruct_CARD_USE_REASON_USE
function chooseToUse(room, source)
	if not banPackages then
		banPackages = sgs.Sanguosha:getBanPackages()
		for pack, types in pairs(cardtypes) do
			if table.contains(banPackages, pack) then
				cardtypes[pack] = {}
			end
		end
		banPackages = true
	end
	local manFlag = #cardtypes["maneuvering"] > 0
	local kofFlag = #cardtypes["New1v1Card"] > 0
	local alives = room:getAlivePlayers()
	local others = room:getOtherPlayers(source)
	local selected = sgs.PlayerList()
	local choices = {}
	--杀
	local card = sgs.Sanguosha:cloneCard("slash")
	card:deleteLater()
	if sgs.Slash_IsAvailable(source) then
		for _,p in sgs.qlist(others) do
			if source:canSlash(p, card) then
				table.insert(choices, "slash")
				if manFlag then
					--火杀
					table.insert(choices, "fire_slash")
					--雷杀
					table.insert(choices, "thunder_slash")
				end
				break
			end
		end
	end
	--桃
	if source:isWounded() then
		if not source:hasFlag("Global_PreventPeach") then
			card = sgs.Sanguosha:cloneCard("peach")
			card:deleteLater()
			if not source:isProhibited(source, card) then
				table.insert(choices, "peach")
			end
		end
	end
	--酒
	if manFlag then
		if sgs.Analeptic_IsAvailable(source) then
			card = sgs.Sanguosha:cloneCard("analeptic")
			card:deleteLater()
			if not source:isProhibited(source, card) then
				table.insert(choices, "analeptic")
			end
		end
	end
	--桃园结义
	card = sgs.Sanguosha:cloneCard("god_salvation")
	card:deleteLater()
	for _,p in sgs.qlist(alives) do
		if not p:isProhibited(source, card) then
			table.insert(choices, "god_salvation")
			break
		end
	end
	--五谷丰登
	card = sgs.Sanguosha:cloneCard("amazing_grace")
	card:deleteLater()
	for _,p in sgs.qlist(alives) do
		if not p:isProhibited(source, card) then
			table.insert(choices, "amazing_grace")
			break
		end
	end
	--南蛮入侵
	card = sgs.Sanguosha:cloneCard("savage_assault")
	card:deleteLater()
	for _,p in sgs.qlist(others) do
		if not p:isProhibited(source, card) then
			table.insert(choices, "savage_assault")
			break
		end
	end
	--万箭齐发
	card = sgs.Sanguosha:cloneCard("archery_attack")
	card:deleteLater()
	for _,p in sgs.qlist(others) do
		if not p:isProhibited(source, card) then
			table.insert(choices, "archery_attack")
			break
		end
	end
	--借刀杀人
	card = sgs.Sanguosha:cloneCard("collateral")
	card:deleteLater()
	for _,p in sgs.qlist(others) do
		if card:targetFilter(selected, p, source) then
			table.insert(choices, "collateral")
			break
		end
	end
	--顺手牵羊
	card = sgs.Sanguosha:cloneCard("snatch")
	card:deleteLater()
	for _,p in sgs.qlist(others) do
		if card:targetFilter(selected, p, source) then
			table.insert(choices, "snatch")
			break
		end
	end
	--过河拆桥
	card = sgs.Sanguosha:cloneCard("dismantlement")
	card:deleteLater()
	for _,p in sgs.qlist(others) do
		if card:targetFilter(selected, p, source) then
			table.insert(choices, "dismantlement")
			break
		end
	end
	--铁索连环
	if manFlag then
		card = sgs.Sanguosha:cloneCard("iron_chain")
		card:deleteLater()
		if card:canRecast() then
			table.insert(choices, "iron_chain")
		else
			for _,p in sgs.qlist(alives) do
				if card:targetFilter(selected, p, source) then
					table.insert(choices, "iron_chain")
					break
				end
			end
		end
	end
	--无中生有
	card = sgs.Sanguosha:cloneCard("ex_nihilo")
	card:deleteLater()
	if not source:isProhibited(source, card) then
		table.insert(choices, "ex_nihilo")
	end
	--水淹七军
	if kofFlag then
		card = sgs.Sanguosha:cloneCard("drowning")
		card:deleteLater()
		for _,p in sgs.qlist(alives) do
			if card:targetFilter(selected, p, source) then
				table.insert(choices, "drowning")
				break
			end
		end
	end
	--火攻
	if manFlag then
		card = sgs.Sanguosha:cloneCard("fire_attack")
		card:deleteLater()
		for _,p in sgs.qlist(alives) do
			if card:targetFilter(selected, p, source) then
				table.insert(choices, "fire_attack")
				break
			end
		end
	end
	--决斗
	card = sgs.Sanguosha:cloneCard("duel")
	card:deleteLater()
	for _,p in sgs.qlist(others) do
		if card:targetFilter(selected, p, source) then
			table.insert(choices, "duel")
			break
		end
	end
	if #choices > 0 then
		choices = table.concat(choices, "+")
		return room:askForChoice(source, "hpKongGuiChooseToUse", choices)
	end
end
function chooseToResponse(room, source, pattern)
	if not banPackages then
		banPackages = sgs.Sanguosha:getBanPackages()
		for pack, types in pairs(cardtypes) do
			if table.contains(banPackages, pack) then
				cardtypes[pack] = {}
			end
		end
		banPackages = true
	end
	if pattern == "" then
		local dying = room:getCurrentDyingPlayer()
		if dying then
			if #cardtypes["maneuvering"] > 0 and dying:objectName() == source:objectName() then
				pattern = "peach+analeptic"
			else
				pattern = "peach"
			end
		end
	end
	if pattern == "peach+analeptic" then
		if source:hasFlag("Global_PreventPeach") then
			pattern = "analeptic"
		end
	end
	local choices = {}
	for pack, names in pairs(cardtypes) do
		for _,name in ipairs(names) do
			local card = sgs.Sanguosha:cloneCard(name)
			card:deleteLater()
			if card:match(pattern) then
				table.insert(choices, name)
			end
		end
	end
	if #choices > 0 then
		choices = table.concat(choices, "+")
		return room:askForChoice(source, "hpKongGuiChooseToResponse", choices)
	end
end
function askForSelectTargets(room, source, cardtype)
	room:setPlayerProperty(source, "hpKongGuiCardType", sgs.QVariant(cardtype))
	local prompt = string.format("@hpKongGuiSelect:::%s:", cardtype)
	local card = room:askForUseCard(source, "@@hpKongGui", prompt)
	room:setPlayerProperty(source, "hpKongGuiCardType", sgs.QVariant(""))
	if card then
		return true
	end
	return false
end
KongGuiCard = sgs.CreateSkillCard{
	name = "hpKongGuiCard",
	target_fixed = true,
	will_throw = true,
	on_validate = function(self, use)
		local user = use.from
		local room = user:getRoom()
		local reason = sgs.Sanguosha:getCurrentCardUseReason()
		local choice = nil
		if reason == _RES_USE then
			local pattern = self:getUserString() or ""
			choice = chooseToResponse(room, user, pattern)
		else
			choice = chooseToUse(room, user)
		end
		if choice then
			local vs_card = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, 0)
			if vs_card:targetFixed() then
				room:setPlayerMark(user, "hpKongGuiInvoked", 1)
				vs_card:setSkillName("hpKongGui")
				return vs_card
			end
			vs_card:deleteLater()
			if askForSelectTargets(room, user, choice) then
				return self
			end
		end
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local pattern = self:getUserString() or ""
		local reason = sgs.Sanguosha:getCurrentCardUseReason()
		local choice = chooseToResponse(room, user, pattern)
		if choice then
			local vs_card = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, 0)
			if vs_card:targetFixed() or reason == _RESPONSE then
				room:setPlayerMark(user, "hpKongGuiInvoked", 1)
				vs_card:setSkillName("hpKongGui")
				return vs_card
			end
			vs_card:deleteLater()
			if askForSelectTargets(room, user, choice) then
				return self
			end
		end
	end,
}
KongGuiSelectCard = sgs.CreateSkillCard{
	name = "hpKongGuiSelectCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		local name = sgs.Self:property("hpKongGuiCardType"):toString() or ""
		local card = sgs.Sanguosha:cloneCard(name)
		if card then
			card:deleteLater()
			local selected = sgs.PlayerList()
			for _,target in ipairs(targets) do
				selected:append(target)
			end
			return card:targetFilter(selected, to_select, sgs.Self)
		end
		return false
	end,
	feasible = function(self, targets)
		local name = sgs.Self:property("hpKongGuiCardType"):toString() or ""
		local card = sgs.Sanguosha:cloneCard(name)
		if card then
			card:deleteLater()
			local selected = sgs.PlayerList()
			for _,target in ipairs(targets) do
				selected:append(target)
			end
			return card:targetsFeasible(selected, sgs.Self)
		end
		return false
	end,
	on_validate = function(self, use)
		local user = use.from
		local room = user:getRoom()
		local name = user:property("hpKongGuiCardType"):toString() or ""
		room:setPlayerProperty(user, "hpKongGuiCardType", sgs.QVariant(""))
		room:setPlayerMark(user, "hpKongGuiInvoked", 1)
		local vs_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
		vs_card:setSkillName("hpKongGui")
		return vs_card
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local name = user:property("hpKongGuiCardType"):toString() or ""
		room:setPlayerProperty(user, "hpKongGuiCardType", sgs.QVariant(""))
		room:setPlayerMark(user, "hpKongGuiInvoked", 1)
		local vs_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
		vs_card:setSkillName("hpKongGui")
		return vs_card
	end,
}
KongGuiVS = sgs.CreateViewAsSkill{
	name = "hpKongGui",
	n = 0,
	ask = "",
	view_as = function(self, cards)
		if ask == "@@hpKongGui" then
			return KongGuiSelectCard:clone()
		else
			local card = KongGuiCard:clone()
			card:setUserString(ask)
			return card
		end
	end,
	enabled_at_play = function(self, player)
		ask = ""
		if player:isKongcheng() and player:getMark("hpKongGuiInvoked") == 0 then
			return true
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		ask = pattern
		if pattern == "@@hpKongGui" then
			return true
		elseif player:isKongcheng() and player:getMark("hpKongGuiInvoked") == 0 then
			if pattern == "peach" and player:getMark("Global_PreventPeach") > 0 then
				return false
			end
			local c = string.sub(pattern, 1, 1)
			if c == "." or c == "@" then
				return false
			end
			if not banPackages then
				banPackages = sgs.Sanguosha:getBanPackages()
				for pack, types in pairs(cardtypes) do
					if table.contains(banPackages, pack) then
						cardtypes[pack] = {}
					end
				end
				banPackages = true
			end
			for pack, types in pairs(cardtypes) do
				for _,cardtype in ipairs(types) do
					local card = sgs.Sanguosha:cloneCard(cardtype)
					card:deleteLater()
					if card:match(pattern) then
						return true
					end
				end
			end
		end
		return false
	end,
	enabled_at_nullification = function(self, player)
		return player:isKongcheng() and player:getMark("hpKongGuiInvoked") == 0
	end,
}
KongGui = sgs.CreateTriggerSkill{
	name = "hpKongGui",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardAsked},
	view_as_skill = KongGuiVS,
	on_trigger = function(self, event, player, data)
		local ask = data:toStringList()
		local pattern = ask[1]
		if pattern == "slash" or pattern == "jink" then
			if player:isKongcheng() and player:getMark("hpKongGuiInvoked") == 0 then
				if player:askForSkillInvoke("hpKongGui", data) then
					local room = player:getRoom()
					room:notifySkillInvoked(player, "hpKongGui") --显示技能发动
					room:setPlayerMark(player, "hpKongGuiInvoked", 1)
					local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
					card:setSkillName("hpKongGui")
					room:provide(card)
					return true
				end
			end
		end
		return false
	end,
}
KongGuiClear = sgs.CreateTriggerSkill{
	name = "#hpKongGuiClear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_NotActive then
			local room = player:getRoom()
			local alives = room:getAlivePlayers()
			for _,source in sgs.qlist(alives) do
				room:setPlayerMark(source, "hpKongGuiInvoked", 0)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
extension:insertRelatedSkills("hpKongGui", "#hpKongGuiClear")
--添加技能
XueBaoChai:addSkill(KongGui)
XueBaoChai:addSkill(KongGuiClear)
--翻译信息
sgs.LoadTranslationTable{
	["hpKongGui"] = "空闺",
	[":hpKongGui"] = "当你需要使用或打出一张基本牌或非延时性锦囊牌时，若你没有手牌，你可以视为使用或打出了此牌。每名角色的回合限一次。",
	["hpKongGuiChooseToUse"] = "空闺",
	["hpKongGuiChooseToResponse"] = "空闺",
	["@hpKongGuiSelect"] = "请为此【%arg】选择必要的目标",
	["~hpKongGui"] = "选择一些目标角色->点击“确定”",
	["hpkonggui"] = "空闺",
}
--[[****************************************************************
	编号：HPIN - 003
	武将：贾元春
	称号：尊情
	势力：蜀
	性别：女
	体力上限：3勾玉
]]--****************************************************************
JiaYuanChun = sgs.General(extension, "hpJiaYuanChun", "shu", 3, false)
--翻译信息
sgs.LoadTranslationTable{
	["hpJiaYuanChun"] = "贾元春",
	["&hpJiaYuanChun"] = "贾元春",
	["#hpJiaYuanChun"] = "尊情",
	["designer:hpJiaYuanChun"] = "DGAH",
	["cv:hpJiaYuanChun"] = "无",
	["illustrator:hpJiaYuanChun"] = "网络资源",
	["~hpJiaYuanChun"] = "贾元春 的阵亡台词",
}
--[[
	技能：省亲
	描述：你或你攻击范围内的一名角色的回合开始时，若你的武将牌正面向上，你可以令其摸两张牌。若如此做，回合结束时，其受到X点伤害（X为其弃牌阶段弃置牌的数目）
]]--
XingQin = sgs.CreateTriggerSkill{
	name = "hpXingQin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Start then
				local alives = room:getAlivePlayers()
				local prompt = string.format("invoke:%s", player:objectName())
				for _,source in sgs.qlist(alives) do
					if source:hasSkill("hpXingQin") and source:faceUp() then
						if source:objectName() == player:objectName() or source:inMyAttackRange(player) then
							if source:askForSkillInvoke("hpXingQin", sgs.QVariant(prompt)) then
								room:broadcastSkillInvoke("hpXingQin") --播放配音
								room:notifySkillInvoked(source, "hpXingQin") --显示技能发动
								player:gainMark("@hpXingQinMark", 1)
								room:drawCards(player, 2, "hpXingQin")
							end
						end
					end
				end
			elseif phase == sgs.Player_Finish then
				if player:getMark("@hpXingQinMark") > 0 then
					player:loseAllMarks("@hpXingQinMark")
					local count = player:getMark("hpXingQinCount")
					if count > 0 then
						room:setPlayerMark(player, "hpXingQinCount", 0)
						local msg = sgs.LogMessage()
						msg.type = "#hpXingQinDamage"
						msg.from = player
						msg.arg = count
						msg.arg2 = "hpXingQin"
						room:sendLog(msg) --发送提示信息
						local damage = sgs.DamageStruct()
						damage.from = nil
						damage.to = player
						damage.damage = count
						damage.reason = "hpXingQin"
						room:damage(damage)
					end
				end
			elseif phase == sgs.Player_NotActive then
				player:loseAllMarks("@hpXingQinMark")
				room:setPlayerMark(player, "hpXingQinCount", 0)
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local source = move.from
			if source and source:objectName() == player:objectName() then
				if player:getPhase() == sgs.Player_Discard and player:getMark("@hpXingQinMark") > 0 then
					local reason = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					if reason == sgs.CardMoveReason_S_REASON_DISCARD then
						for index, place in sgs.qlist(move.from_places) do
							if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip then
								room:addPlayerMark(player, "hpXingQinCount", 1)
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
--添加技能
JiaYuanChun:addSkill(XingQin)
--翻译信息
sgs.LoadTranslationTable{
	["hpXingQin"] = "省亲",
	[":hpXingQin"] = "你或你攻击范围内的一名角色的回合开始时，若你的武将牌正面向上，你可以令其摸两张牌。若如此做，回合结束时，其受到X点伤害（X为其弃牌阶段弃置牌的数目）",
	["hpXingQin:invoke"] = "您想对 %src 发动“省亲”吗？",
	["#hpXingQinDamage"] = "%from 弃牌阶段弃置了 %arg 张牌，受技能“%arg2”影响，将受到 %arg 点伤害",
	["@hpXingQinMark"] = "亲",
}
--[[
	技能：宫恨（锁定技）
	描述：一名角色的回合结束后，若你于该回合内对其发动过“省亲”，你执行第X项：1、不能使用或打出红色牌直到你的下回合开始；2、失去1点体力；3、摸一张牌并翻面；4、立即死亡。（X为你上回合结束后已发动“省亲”的次数且至多为4）
]]--
GongHen = sgs.CreateTriggerSkill{
	name = "hpGongHen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ChoiceMade, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.ChoiceMade then
			if data:toString() == "skillInvoke:hpXingQin:yes" then
				room:setPlayerMark(player, "hpXingQinSource", 1)
				room:addPlayerMark(player, "hpXingQinTimes", 1)
			end
		elseif event == sgs.EventPhaseStart then
			local phase = player:getPhase()
			if phase == sgs.Player_Start then
				room:setPlayerMark(player, "hpXingQinTimes", 0)
				if player:getMark("hpGongHenEffect") > 0 then
					room:setPlayerMark(player, "hpGongHenEffect", 0)
					room:removePlayerCardLimitation(player, "use,response", ".|red|.|.$0")
					local msg = sgs.LogMessage()
					msg.type = "#hpGongHenClear"
					msg.from = player
					room:sendLog(msg) --发送提示信息
				end
			elseif phase == sgs.Player_NotActive then
				local alives = room:getAlivePlayers()
				for _,source in sgs.qlist(alives) do
					if source:getMark("hpXingQinSource") > 0 then
						room:setPlayerMark(source, "hpXingQinSource", 0)
						local times = source:getMark("hpXingQinTimes")
						times = math.min( 4, times )
						room:broadcastSkillInvoke("hpGongHen") --播放配音
						room:sendCompulsoryTriggerLog(source, "hpGongHen") --显示技能发动
						if times == 1 then
							room:setPlayerMark(source, "hpGongHenEffect", 1)
							room:setPlayerCardLimitation(source, "use,response", ".|red|.|.$0", false)
							local msg = sgs.LogMessage()
							msg.type = "#hpGongHenLimit"
							msg.from = source
							room:sendLog(msg) --发送提示信息
						elseif times == 2 then
							room:loseHp(source, 1)
						elseif times == 3 then
							room:drawCards(source, 1, "hpGongHen")
							source:turnOver()
						elseif times == 4 then
							room:killPlayer(source)
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 3,
}
--添加技能
JiaYuanChun:addSkill(GongHen)
--翻译信息
sgs.LoadTranslationTable{
	["hpGongHen"] = "宫恨",
	[":hpGongHen"] = "<font color=\"blue\"><b>锁定技</b></font>，一名角色的回合结束后，若你于该回合内对其发动过“省亲”，你执行第X项：1、不能使用或打出红色牌直到你的下回合开始；2、失去1点体力；3、摸一张牌并翻面；4、立即死亡。（X为你上回合结束后已发动“省亲”的次数且至多为4）",
	["hpGongHen:turnover"] = "摸两张牌并翻面",
	["hpGongHen:limit"] = "不能使用或打出红色牌至下回合开始",
	["#hpGongHenLimit"] = "%from 受到“宫恨”的影响，不能使用或打出红色牌直到其下个回合开始",
	["#hpGongHenClear"] = "%from 的回合开始，受“宫恨”的影响消失",
}
--[[****************************************************************
	编号：HPIN - 004
	武将：贾探春
	称号：敏情
	势力：魏
	性别：女
	体力上限：3勾玉
]]--****************************************************************
JiaTanChun = sgs.General(extension, "hpJiaTanChun", "wei", 3, false)
--翻译信息
sgs.LoadTranslationTable{
	["hpJiaTanChun"] = "贾探春",
	["&hpJiaTanChun"] = "贾探春",
	["#hpJiaTanChun"] = "敏情",
	["designer:hpJiaTanChun"] = "DGAH",
	["cv:hpJiaTanChun"] = "无",
	["illustrator:hpJiaTanChun"] = "网络资源",
	["~hpJiaTanChun"] = "贾探春 的阵亡台词",
}
--[[
	技能：结社
	描述：出牌阶段限一次，若你有手牌，你可以选择至少一名有手牌的其他角色，你与这些角色同时打出一张手牌。打出牌点数最大者若唯一，其摸一张牌，然后其可以从所有参与打出牌的角色中选择任意数目的角色，令这些角色各摸一张牌。
]]--
JieSheCard = sgs.CreateSkillCard{
	name = "hpJieSheCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if to_select:objectName() == sgs.Self:objectName() then
			return false
		elseif to_select:isKongcheng() then
			return false
		end
		return true
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("hpJieShe") --播放配音
		table.insert(targets, 1, source)
		local cards = {}
		local maxpoint, winner = 0, nil
		local prompt = string.format("@hpJieShe:%s:", source:objectName())
		local data = sgs.QVariant()
		data:setValue(source)
		local can_draw = sgs.SPlayerList()
		for _,target in ipairs(targets) do
			if target:isAlive() and not target:isKongcheng() then
				local card = room:askForCard(target, ".!", prompt, data, sgs.Card_MethodPindian, nil, false, "hpJieShe", true)
				if not card then
					card = target:getRandomHandCard()
				end
				cards[target] = card
				local point = card:getNumber()
				if point > maxpoint then
					maxpoint = point
					winner = target
				elseif point == maxpoint then
					winner = nil
				end
				can_draw:append(target)
			end
		end
		local moves = sgs.CardsMoveList()
		for target, card in pairs(cards) do
			local id = card:getEffectiveId()
			local move = sgs.CardsMoveStruct()
			move.card_ids:append(id)
			move.from = target
			move.to = nil
			move.to_place = sgs.Player_PlaceTable
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN, target:objectName())
			moves:append(move)
			local msg = sgs.LogMessage()
			msg.type = "$PindianResult"
			msg.from = target
			msg.card_str = id
			room:sendLog(msg) --发送提示信息
		end
		room:moveCardsAtomic(moves, true)
		room:getThread():delay()
		if winner then
			room:drawCards(winner, 1, "hpJieShe")
		end
		moves = sgs.CardsMoveList()
		for target, card in pairs(cards) do
			local id = card:getEffectiveId()
			local place = room:getCardPlace(id)
			if place == sgs.Player_PlaceTable then
				local move = sgs.CardsMoveStruct()
				move.card_ids:append(id)
				move.from = nil
				move.from_place = sgs.Player_PlaceTable
				move.to = nil
				move.to_place = sgs.Player_DiscardPile
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN, target:objectName())
				moves:append(move)
			end
		end
		room:moveCardsAtomic(moves, true)
		if winner then
			local to_draw = sgs.SPlayerList()
			local n = 0
			while not can_draw:isEmpty() do
				local prompt = string.format("@hpJieShe-draw:::%d:", n)
				local target = room:askForPlayerChosen(winner, can_draw, "hpJieShe", prompt, true)
				if target then
					to_draw:append(target)
					can_draw:removeOne(target)
					n = n + 1
				else
					break
				end
			end
			if not to_draw:isEmpty() then
				room:drawCards(to_draw, 1, "hpJieShe")
			end
		end
	end,
}
JieShe = sgs.CreateViewAsSkill{
	name = "hpJieShe",
	n = 0,
	view_as = function(self, cards)
		return JieSheCard:clone()
	end,
	enabled_at_play = function(self, player)
		if player:hasUsed("#hpJieSheCard") then
			return false
		elseif player:isKongcheng() then
			return false
		end
		return true
	end,
}
--添加技能
JiaTanChun:addSkill(JieShe)
--翻译信息
sgs.LoadTranslationTable{
	["hpJieShe"] = "结社",
	[":hpJieShe"] = "<font color=\"green\"><b>出牌阶段限一次</b></font>，若你有手牌，你可以选择至少一名有手牌的其他角色，你与这些角色同时打出一张手牌。打出牌点数最大者若唯一，其摸一张牌，然后其可以从所有参与打出牌的角色中选择任意数目的角色，令这些角色各摸一张牌。",
	["@hpJieShe"] = "%src 发起了“结社”，请打出一张手牌参与比较点数大小",
	["@hpJieShe-draw"] = "您可以继续选择一名参与结社的角色，令其摸一张牌（目前已选 %arg 人）",
	["hpjieshe"] = "结社",
}
--[[
	技能：变革
	描述：一名与你距离为1以内的角色的出牌阶段开始时，你可以令其摸X张牌。若如此做，当前出牌阶段结束时，该角色弃X张牌（X为其已损失的体力）
]]--
BianGe = sgs.CreateTriggerSkill{
	name = "hpBianGe",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Play then
			local room = player:getRoom()
			if event == sgs.EventPhaseStart then
				local x = player:getLostHp()
				if x <= 0 then
					return false
				end
				local sources = {}
				local alives = room:getAlivePlayers()
				for _,p in sgs.qlist(alives) do
					if p:hasSkill("hpBianGe") and p:distanceTo(player) <= 1 then
						table.insert(sources, p)
					end
				end
				local prompt = string.format("invoke:%s::%d:", player:objectName(), x)
				for _,source in ipairs(sources) do
					if source:askForSkillInvoke("hpBianGe", sgs.QVariant(prompt)) then
						room:drawCards(player, x, "hpBianGe")
						room:setPlayerFlag(player, "hpBianGeInvoked")
					end
				end
			elseif event == sgs.EventPhaseEnd then
				if player:hasFlag("hpBianGeInvoked") then
					room:setPlayerFlag(player, "-hpBianGeInvoked")
					local x = player:getLostHp()
					if x > 0 then
						local prompt = string.format("@hpBianGe:::%d:", x)
						room:askForDiscard(player, "hpBianGe", x, x, false, true, prompt)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
--添加技能
JiaTanChun:addSkill(BianGe)
--翻译信息
sgs.LoadTranslationTable{
	["hpBianGe"] = "变革",
	[":hpBianGe"] = "一名与你距离为1以内的角色的出牌阶段开始时，你可以令其摸X张牌。若如此做，当前出牌阶段结束时，该角色弃X张牌（X为其已损失的体力）",
	["hpBianGe:invoke"] = "您想对 %src 发动技能“变革”，让其摸 %arg 张牌吗？",
	["@hpBianGe"] = "受技能“变革”影响，您需要弃置 %arg 张牌（包括装备）",
}
--[[****************************************************************
	编号：HPIN - 005
	武将：史湘云
	称号：憨情
	势力：蜀
	性别：女
	体力上限：4勾玉
]]--****************************************************************
ShiXiangYun = sgs.General(extension, "hpShiXiangYun", "shu", 4, false)
--翻译信息
sgs.LoadTranslationTable{
	["hpShiXiangYun"] = "史湘云",
	["&hpShiXiangYun"] = "史湘云",
	["#hpShiXiangYun"] = "憨情",
	["designer:hpShiXiangYun"] = "DGAH",
	["cv:hpShiXiangYun"] = "无",
	["illustrator:hpShiXiangYun"] = "网络资源",
	["~hpShiXiangYun"] = "史湘云 的阵亡台词",
}
--[[
	技能：醉石
	描述：你使用一张【酒】时，可以摸三张牌。
]]--
ZuiShi = sgs.CreateTriggerSkill{
	name = "hpZuiShi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local anal = use.card
		if anal and anal:isKindOf("Analeptic") then
			if player:askForSkillInvoke("hpZuiShi", data) then
				local room = player:getRoom()
				room:broadcastSkillInvoke("hpZuiShi") --播放配音
				room:notifySkillInvoked(player, "hpZuiShi") --显示技能发动
				room:drawCards(player, 3, "hpZuiShi")
			end
		end
		return false
	end,
}
--添加技能
ShiXiangYun:addSkill(ZuiShi)
--翻译信息
sgs.LoadTranslationTable{
	["hpZuiShi"] = "醉石",
	[":hpZuiShi"] = "你使用一张【酒】时，可以摸三张牌。",
}
--[[
	技能：性情
	描述：出牌阶段限一次，你可以选择一项：
		1、弃置一张基本牌，视为对一名其他角色使用了一张【杀】。
		2、弃置一张锦囊牌，令一名角色摸两张牌。
		3、弃置一张装备牌，弃置场上至多两张牌。
		4、对自己造成1点伤害，视为使用了一张【酒】。
]]--
XingQingBasicCard = sgs.CreateSkillCard{
	name = "hpXingQingBasicCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return sgs.Self:canSlash(to_select)
		end
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("hpXingQing", 1) --播放配音
		local target = targets[1]
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("hpXingQing")
		local use = sgs.CardUseStruct()
		use.from = source
		use.to:append(target)
		use.card = slash
		room:useCard(use, false)
	end,
}
XingQingTrickCard = sgs.CreateSkillCard{
	name = "hpXingQingTrickCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	feasible = function(self, targets)
		return true
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("hpXingQing", 2) --播放配音
		local target = targets[1] or source
		room:drawCards(target, 2, "hpXingQing")
	end,
}
XingQingEquipCard = sgs.CreateSkillCard{
	name = "hpXingQingEquipCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets < 2 then
			if to_select:hasEquip() and sgs.Self:canDiscard(to_select, "e") then
				return true
			elseif to_select:getJudgingArea():isEmpty() then
				return false
			elseif sgs.Self:canDiscard(to_select, "j") then
				return true
			end
		end
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("hpXingQing", 3) --播放配音
		local count = 0
		for _,target in ipairs(targets) do
			if not target:getCards("ej"):isEmpty() then
				local id = room:askForCardChosen(source, target, "ej", "hpXingQing")
				if id > 0 then
					room:throwCard(id, target, source)
					count = count + 1
				end
			end
		end
		if count == 1 then
			local alives = room:getAlivePlayers()
			local victims = sgs.SPlayerList()
			for _,p in sgs.qlist(alives) do
				if p:hasEquip() and source:canDiscard(p, "e") then
					victims:append(p)
				elseif p:getJudgingArea():isEmpty() then
				elseif source:canDiscard(p, "j") then
					victims:append(p)
				end
			end
			if victims:isEmpty() then
				return 
			end
			local victim = room:askForPlayerChosen(source, victims, "hpXingQing", "@hpXingQing", true)
			if victim then
				local id = room:askForCardChosen(source, victim, "ej", "hpXingQing")
				if id > 0 then
					room:throwCard(id, victim, source)
				end
			end
		end
	end,
}
XingQingCard = sgs.CreateSkillCard{
	name = "hpXingQingCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("hpXingQing", 4) --播放配音
		local damage = sgs.DamageStruct()
		damage.from = source
		damage.to = source
		damage.damage = 1
		damage.reason = "hpXingQing"
		room:damage(damage)
		if source:isAlive() then
			local anal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
			anal:setSkillName("hpXingQing")
			local use = sgs.CardUseStruct()
			use.from = source
			use.to:append(source)
			use.card = anal
			room:useCard(use, true)
		end
	end,
}
XingQing = sgs.CreateViewAsSkill{
	name = "hpXingQing",
	n = 1,
	view_filter = function(self, selected, to_select)
		local id = to_select:getEffectiveId()
		if sgs.Self:canDiscard(sgs.Self, id) then
			if to_select:isKindOf("BasicCard") then
				return sgs.Slash_IsAvailable(sgs.Self)
			end
			return true
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return XingQingCard:clone()
		elseif #cards == 1 then
			local card = cards[1]
			local vs_card = nil
			if card:isKindOf("BasicCard") then
				vs_card = XingQingBasicCard:clone()
			elseif card:isKindOf("TrickCard") then
				vs_card = XingQingTrickCard:clone()
			elseif card:isKindOf("EquipCard") then
				vs_card = XingQingEquipCard:clone()
			end
			if vs_card then
				vs_card:addSubcard(card)
				return vs_card
			end
		end
	end,
	enabled_at_play = function(self, player)
		if player:hasUsed("#hpXingQingCard") then
			return false
		elseif player:hasUsed("#hpXingQingBasicCard") then
			return false
		elseif player:hasUsed("#hpXingQingTrickCard") then
			return false
		elseif player:hasUsed("#hpXingQingEquipCard") then
			return false
		elseif sgs.Analeptic_IsAvailable(player) then
			return true
		elseif player:isNude() then
			return false
		elseif player:canDiscard(player, "he") then
			return true
		end
		return false
	end,
}
--添加技能
ShiXiangYun:addSkill(XingQing)
--翻译信息
sgs.LoadTranslationTable{
	["hpXingQing"] = "性情",
	[":hpXingQing"] = "<font color=\"green\"><b>出牌阶段限一次</b></font>，你可以选择一项：\
1、弃置一张基本牌，视为对一名其他角色使用了一张【杀】。\
2、弃置一张锦囊牌，令一名角色摸两张牌。\
3、弃置一张装备牌，弃置场上至多两张牌。\
4、对自己造成1点伤害，视为使用了一张【酒】。",
	["@hpXingQing"] = "性情：您可以继续弃置场上的一张牌",
	["hpxingqingbasic"] = "性情",
	["hpxingqingtrick"] = "性情",
	["hpxingqingequip"] = "性情",
	["hpxingqing"] = "性情",
}
--[[****************************************************************
	编号：HPIN - 006
	武将：妙玉
	称号：隐情
	势力：群
	性别：女
	体力上限：3勾玉
]]--****************************************************************
MiaoYu = sgs.General(extension, "hpMiaoYu", "qun", 3, false)
--翻译信息
sgs.LoadTranslationTable{
	["hpMiaoYu"] = "妙玉",
	["&hpMiaoYu"] = "妙玉",
	["#hpMiaoYu"] = "隐情",
	["designer:hpMiaoYu"] = "DGAH",
	["cv:hpMiaoYu"] = "无",
	["illustrator:hpMiaoYu"] = "网络资源",
	["~hpMiaoYu"] = "妙玉 的阵亡台词",
}
--[[
	技能：梅雪
	描述：准备阶段开始时，你可以观看牌堆顶的X张牌，然后你可以将其中一张非黑桃牌交给一名角色，将其余的牌以任意次序置于牌堆顶（X为你的体力且至少为1、至多为5）。若该角色不为你，回合结束时，你摸一张牌。
]]--
MeiXue = sgs.CreateTriggerSkill{
	name = "hpMeiXue",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Start then
			if player:askForSkillInvoke("hpMeiXue", data) then
				local x = player:getHp()
				x = math.min(5, math.max(1, x))
				local card_ids = room:getNCards(x)
				local can_give = sgs.IntList()
				local cannot_give = sgs.IntList()
				for _,id in sgs.qlist(card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:getSuit() == sgs.Card_Spade then
						cannot_give:append(id)
					else
						can_give:append(id)
					end
				end
				if not can_give:isEmpty() then
					room:fillAG(card_ids, player, cannot_give)
					local to_give = room:askForAG(player, can_give, true, "hpMeiXue")
					room:clearAG(player)
					if to_give >= 0 then
						local card = sgs.Sanguosha:getCard(to_give)
						local alives = room:getAlivePlayers()
						local prompt = string.format("@hpMeiXue:::%s:", card:objectName())
						player:setTag("hpMeiXueCardID", sgs.QVariant(to_give)) --For AI
						local target = room:askForPlayerChosen(player, alives, "hpMeiXue", prompt, true)
						player:removeTag("hpMeiXueCardID") --For AI
						if target then
							room:obtainCard(target, to_give, true)
							card_ids:removeOne(to_give)
							if target:objectName() ~= player:objectName() then
								room:addPlayerMark(player, "hpMeiXueInvoked", 1)
							end
						end
					end
				end
				if not card_ids:isEmpty() then
					room:askForGuanxing(player, card_ids, sgs.Room_GuanxingUpOnly)
				end
			end
		elseif phase == sgs.Player_Finish then
			local count = player:getMark("hpMeiXueInvoked")
			if count > 0 then
				room:setPlayerMark(player, "hpMeiXueInvoked", 0)
				room:drawCards(player, count, "hpMeiXue")
			end
		end
		return false
	end,
}
--添加技能
MiaoYu:addSkill(MeiXue)
--翻译信息
sgs.LoadTranslationTable{
	["hpMeiXue"] = "梅雪",
	[":hpMeiXue"] = "准备阶段开始时，你可以观看牌堆顶的X张牌，然后你可以将其中一张非黑桃牌交给一名角色，将其余的牌以任意次序置于牌堆顶（X为你的体力且至少为1）。若该角色不为你，回合结束时，你摸一张牌。",
	["@hpMeiXue"] = "梅雪：您可以将此【%arg】交给一名角色。若不为你，回合结束时你摸一张牌",
}
--[[
	技能：劫数（锁定技）
	描述：你受到【南蛮入侵】造成的伤害+1；以你为目标的【南蛮入侵】结算完成后，你摸两张牌。
]]--
JieShu = sgs.CreateTriggerSkill{
	name = "hpJieShu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			local victim = damage.to
			if victim and victim:objectName() == player:objectName() then
				if player:isAlive() and player:hasSkill("hpJieShu") then
					local aoe = damage.card
					if aoe and aoe:isKindOf("SavageAssault") then
						room:broadcastSkillInvoke("hpJieShu") --播放配音
						room:notifySkillInvoked(player, "hpJieShu") --显示技能发动
						local msg = sgs.LogMessage()
						msg.type = "#hpJieShuEffect"
						msg.from = player
						local count = damage.damage
						msg.arg = count
						count = count + 1
						msg.arg2 = count
						room:sendLog(msg) --发送提示信息
						damage.damage = count
						data:setValue(damage)
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local aoe = use.card
			if aoe and aoe:isKindOf("SavageAssault") then
				local targets = use.to
				for _,source in sgs.qlist(targets) do
					if source:isAlive() and source:hasSkill("hpJieShu") then
						room:drawCards(source, 2, "hpJieShu")
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--添加技能
MiaoYu:addSkill(JieShu)
--翻译信息
sgs.LoadTranslationTable{
	["hpJieShu"] = "劫数",
	[":hpJieShu"] = "<font color=\"blue\"><b>锁定技</b></font>，你受到【南蛮入侵】造成的伤害+1；以你为目标的【南蛮入侵】结算完成后，你摸两张牌。",
	["#hpJieShuEffect"] = "%from 的技能“劫数”被触发，受到此【南蛮入侵】造成的伤害+1，从 %arg 点上升至 %arg2 点",
}
--[[****************************************************************
	编号：HPIN - 007
	武将：贾迎春
	称号：懦情
	势力：魏
	性别：女
	体力上限：3勾玉
]]--****************************************************************
JiaYingChun = sgs.General(extension, "hpJiaYingChun", "wei", 3, false)
--翻译信息
sgs.LoadTranslationTable{
	["hpJiaYingChun"] = "贾迎春",
	["&hpJiaYingChun"] = "贾迎春",
	["#hpJiaYingChun"] = "懦情",
	["designer:hpJiaYingChun"] = "DGAH",
	["cv:hpJiaYingChun"] = "无",
	["illustrator:hpJiaYingChun"] = "网络资源",
	["~hpJiaYingChun"] = "贾迎春 的阵亡台词",
}
--[[
	技能：如木（锁定技）
	描述：每当你于一名角色的回合内受到伤害时，若为你本回合第一次受到伤害，你防止之；每当你于出牌阶段内造成伤害时，若为你本阶段第一次造成伤害，你防止之并摸两张牌。
]]--
RuMu = sgs.CreateTriggerSkill{
	name = "hpRuMu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted, sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.DamageInflicted then
			local current = room:getCurrent()
			if current and current:isAlive() then
				if player:getMark("hpRuMuVictim") == 0 then
					room:broadcastSkillInvoke("hpRuMu", 1) --播放配音
					room:notifySkillInvoked(player, "hpRuMu") --显示技能发动
					local msg = sgs.LogMessage()
					msg.type = "#hpRuMuVictim"
					msg.from = player
					msg.arg = "hpRuMu"
					room:sendLog(msg) --发送提示信息
					room:setPlayerMark(player, "hpRuMuVictim", 1)
					return true
				end
			end
		elseif event == sgs.DamageCaused then
			if player:getPhase() == sgs.Player_Play then
				if player:getMark("hpRuMuSource") == 0 then
					room:broadcastSkillInvoke("hpRuMu", 2) --播放配音
					room:notifySkillInvoked(player, "hpRuMu") --显示技能发动
					local msg = sgs.LogMessage()
					msg.type = "#hpRuMuSource"
					msg.from = player
					msg.arg = "hpRuMu"
					room:sendLog(msg) --发送提示信息
					room:setPlayerMark(player, "hpRuMuSource", 1)
					room:drawCards(player, 2, "hpRuMu")
					return true
				end
			end
		end
		return false
	end,
}
RuMuClear = sgs.CreateTriggerSkill{
	name = "#hpRuMuClear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_NotActive then
			local room = player:getRoom()
			local alives = room:getAlivePlayers()
			for _,p in sgs.qlist(alives) do
				room:setPlayerMark(p, "hpRuMuVictim", 0)
				room:setPlayerMark(p, "hpRuMuSource", 0)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
extension:insertRelatedSkills("hpRuMu", "#hpRuMuClear")
--添加技能
JiaYingChun:addSkill(RuMu)
JiaYingChun:addSkill(RuMuClear)
--翻译信息
sgs.LoadTranslationTable{
	["hpRuMu"] = "如木",
	[":hpRuMu"] = "<font color=\"blue\"><b>锁定技</b></font>，每当你于一名角色的回合内受到伤害时，若为你本回合第一次受到伤害，你防止之；<font color=\"blue\"><b>锁定技</b></font>，每当你于出牌阶段内造成伤害时，若为你本阶段第一次造成伤害，你防止之并摸两张牌。",
	["#hpRuMuVictim"] = "%from 的技能“%arg”被触发，防止了本回合受到的第一次伤害",
	["#hpRuMuSource"] = "%from 的技能“%arg”被触发，防止了本阶段造成的第一次伤害，改为摸两张牌",
}
--[[
	技能：忍辱（锁定技）
	描述：你的【无懈可击】视为【铁索连环】。
]]--
RenRu = sgs.CreateFilterSkill{
	name = "hpRenRu",
	view_filter = function(self, to_select)
		return to_select:isKindOf("Nullification")
	end,
	view_as = function(self, card)
		local id = card:getEffectiveId()
		local wrapped = sgs.Sanguosha:getWrappedCard(id)
		local suit = card:getSuit()
		local point = card:getNumber()
		local iron_chain = sgs.Sanguosha:cloneCard("iron_chain", suit, point)
		iron_chain:setSkillName("hpRenRu")
		wrapped:takeOver(iron_chain)
		return wrapped
	end,
}
--添加技能
JiaYingChun:addSkill(RenRu)
--翻译信息
sgs.LoadTranslationTable{
	["hpRenRu"] = "忍辱",
	[":hpRenRu"] = "<font color=\"blue\"><b>锁定技</b></font>，你的【无懈可击】视为【铁索连环】。",
}
--[[****************************************************************
	编号：HPIN - 008
	武将：贾惜春
	称号：冷情
	势力：群
	性别：女
	体力上限：3勾玉
]]--****************************************************************
JiaXiChun = sgs.General(extension, "hpJiaXiChun", "qun", 3, false)
--翻译信息
sgs.LoadTranslationTable{
	["hpJiaXiChun"] = "贾惜春",
	["&hpJiaXiChun"] = "贾惜春",
	["#hpJiaXiChun"] = "冷情",
	["designer:hpJiaXiChun"] = "DGAH",
	["cv:hpJiaXiChun"] = "无",
	["illustrator:hpJiaXiChun"] = "网络资源",
	["~hpJiaXiChun"] = "贾惜春 的阵亡台词",
}
--[[
	技能：冷绝
	描述：一名角色对你攻击范围内的另一名角色使用【桃】时，你可以弃一张手牌，令此【桃】对目标角色无效。
]]--
LengJue = sgs.CreateTriggerSkill{
	name = "hpLengJue",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardEffected},
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		local peach = effect.card
		if peach and peach:isKindOf("Peach") then
			local victim = effect.to
			if victim and victim:objectName() == player:objectName() then
				local source = effect.from
				if source and source:objectName() ~= player:objectName() then
					local room = player:getRoom()
					local alives = room:getAlivePlayers()
					local prompt = string.format("@hpLengJue:%s:%s:", source:objectName(), victim:objectName())
					for _,p in sgs.qlist(alives) do
						if p:hasSkill("hpLengJue") and p:inMyAttackRange(victim) then
							if p:isKongcheng() then
							elseif p:canDiscard(p, "h") then
								local card = room:askForCard(p, ".", prompt, data, "hpLengJue")
								if card then
									room:broadcastSkillInvoke("hpLengJue") --播放配音
									room:notifySkillInvoked(p, "hpLengJue") --显示技能发动
									local msg = sgs.LogMessage()
									msg.type = "#hpLengJue"
									msg.from = p
									msg.to:append(victim)
									room:sendLog(msg) --发送提示信息
									return true
								end
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
--添加技能
JiaXiChun:addSkill(LengJue)
--翻译信息
sgs.LoadTranslationTable{
	["hpLengJue"] = "冷绝",
	[":hpLengJue"] = "一名角色对你攻击范围内的另一名角色使用【桃】时，你可以弃一张手牌，令此【桃】对目标角色无效。",
	["@hpLengJue"] = "%src 对 %dest 使用了【桃】，您可以发动“冷绝”弃置一张手牌，令此【桃】对 %dest 无效",
	["#hpLengJue"] = "受 %from 的技能“冷绝”的影响，此【桃】对 %to 无效",
}
--[[
	技能：弃世（限定技）
	描述：出牌阶段，你可以弃置区域中的所有牌，将武将牌恢复至游戏开始时的状态，摸四张牌，然后失去技能“冷绝”并获得技能“飞影”和“帷幕”。
]]--
QiShiCard = sgs.CreateSkillCard{
	name = "hpQiShiCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("hpQiShi") --播放配音
		room:notifySkillInvoked(source, "hpQiShi")
		source:loseMark("@hpQiShiMark", 1)
		source:throwAllHandCardsAndEquips()
		local judges = source:getJudgingArea()
		if not judges:isEmpty() then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, source:objectName())
			for _,judge in sgs.qlist(judges) do
				room:throwCard(judge, reason)
			end
		end
		if not source:faceUp() then
			source:turnOver()
		end
		if source:isChained() then
			source:setChained(false)
			room:broadcastProperty(source, "chained")
			room:setEmotion(source, "chain")
			room:getThread():trigger(sgs.ChainStateChanged, room, source)
		end
		room:drawCards(source, 4, "hpQiShi")
		room:handleAcquireDetachSkills(source, "-hpLengJue|feiying|weimu", false)
	end,
}
QiShiVS = sgs.CreateViewAsSkill{
	name = "hpQiShi",
	n = 0,
	view_as = function(self, card)
		return QiShiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@hpQiShiMark") > 0
	end,
}
QiShi = sgs.CreateTriggerSkill{
	name = "hpQiShi",
	frequency = sgs.Skill_Limited,
	events = {},
	view_as_skill = QiShiVS,
	limit_mark = "@hpQiShiMark",
	on_trigger = function(self, event, player, data)
	end,
}
--添加技能
JiaXiChun:addSkill(QiShi)
--翻译信息
sgs.LoadTranslationTable{
	["hpQiShi"] = "弃世",
	[":hpQiShi"] = "<font color=\"red\"><b>限定技</b></font>，出牌阶段，你可以弃置区域中的所有牌，将武将牌恢复至游戏开始时的状态，摸四张牌，然后失去技能“冷绝”并获得技能“飞影”和“帷幕”。",
	["@hpQiShiMark"] = "弃世",
	["hpqishi"] = "弃世",
}
--[[****************************************************************
	编号：HPIN - 009
	武将：王熙凤
	称号：雄情
	势力：吴
	性别：女
	体力上限：4勾玉
]]--****************************************************************
WangXiFeng = sgs.General(extension, "hpWangXiFeng", "wu", 4, false)
--翻译信息
sgs.LoadTranslationTable{
	["hpWangXiFeng"] = "王熙凤",
	["&hpWangXiFeng"] = "王熙凤",
	["#hpWangXiFeng"] = "雄情",
	["designer:hpWangXiFeng"] = "DGAH",
	["cv:hpWangXiFeng"] = "无",
	["illustrator:hpWangXiFeng"] = "网络资源",
	["~hpWangXiFeng"] = "王熙凤 的阵亡台词",
}
--[[
	技能：弄权
	描述：出牌阶段限一次，你可以选择两名角色，其中的每名角色均须交给你一张牌，否则受到另一名角色造成的1点伤害。若你以此法从其他角色处获得了两张牌，你摸一张牌并失去1点体力。
]]--
function doNongQuan(room, source, current, other)
	if current:isAlive() then
		if source:isAlive() then
			local prompt = string.format("@hpNongQuan:%s:%s:", source:objectName(), other:objectName())
			local data = sgs.QVariant()
			data:setValue(other)
			local card = room:askForCard(current, "..", prompt, data, sgs.Card_MethodNone, source, false, "hpNongQuan", true)
			if card then
				room:obtainCard(source, card, true)
				if source:objectName() ~= current:objectName() then
					room:addPlayerMark(source, "hpNongQuanCount", 1)
				end
				return 
			end
		end
		if other:isAlive() then
			local damage = sgs.DamageStruct()
			damage.from = other
			damage.to = current
			damage.damage = 1
			damage.reason = "hpNongQuan"
			room:damage(damage)
		end
	end
end
NongQuanCard = sgs.CreateSkillCard{
	name = "hpNongQuanCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets < 2
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("hpNongQuan") --播放配音
		room:notifySkillInvoked(source, "hpNongQuan") --显示技能发动
		local targetA, targetB = targets[1], targets[2]
		doNongQuan(room, source, targetA, targetB)
		doNongQuan(room, source, targetB, targetA)
		if source:getMark("hpNongQuanCount") == 2 then
			room:drawCards(source, 1, "hpNongQuan")
			room:loseHp(source, 1)
		end
		room:setPlayerMark(source, "hpNongQuanCount", 0)
	end,
}
NongQuan = sgs.CreateViewAsSkill{
	name = "hpNongQuan",
	n = 0,
	view_as = function(self, cards)
		return NongQuanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#hpNongQuanCard")
	end,
}
--添加技能
WangXiFeng:addSkill(NongQuan)
--翻译信息
sgs.LoadTranslationTable{
	["hpNongQuan"] = "弄权",
	[":hpNongQuan"] = "<font color=\"green\"><b>出牌阶段限一次</b></font>，你可以选择两名角色，其中的每名角色均须交给你一张牌，否则受到另一名角色造成的1点伤害。若你以此法从其他角色处获得了两张牌，你摸一张牌并失去1点体力。",
	["@hpNongQuan"] = "%src 对你发动了“弄权”，请交给其一张牌（包括装备），否则 %dest 将对你造成 1 点伤害",
	["hpnongquan"] = "弄权",
}
--[[
	技能：算尽（锁定技）
	描述：你濒死时，失去1点体力上限。
]]--
SuanJin = sgs.CreateTriggerSkill{
	name = "hpSuanJin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
		local dying = data:toDying()
		local victim = dying.who
		if victim and victim:objectName() == player:objectName() then
			local room = player:getRoom()
			room:broadcastSkillInvoke("hpSuanJin") --播放配音
			room:notifySkillInvoked(player, "hpSuanJin") --显示技能发动
			room:sendCompulsoryTriggerLog(player, "hpSuanJin", true) --发送锁定技触发信息
			room:loseMaxHp(player, 1)
		end
		return false
	end,
}
--添加技能
WangXiFeng:addSkill(SuanJin)
--翻译信息
sgs.LoadTranslationTable{
	["hpSuanJin"] = "算尽",
	[":hpSuanJin"] = "<font color=\"blue\"><b>锁定技</b></font>，你濒死时，失去1点体力上限。",
}
--[[****************************************************************
	编号：HPIN - 010
	武将：贾巧姐
	称号：恩情
	势力：吴
	性别：女
	体力上限：3勾玉
]]--****************************************************************
JiaQiaoJie = sgs.General(extension, "hpJiaQiaoJie", "wu", 3, false)
--翻译信息
sgs.LoadTranslationTable{
	["hpJiaQiaoJie"] = "贾巧姐",
	["&hpJiaQiaoJie"] = "贾巧姐",
	["#hpJiaQiaoJie"] = "恩情",
	["designer:hpJiaQiaoJie"] = "DGAH",
	["cv:hpJiaQiaoJie"] = "无",
	["illustrator:hpJiaQiaoJie"] = "网络资源",
	["~hpJiaQiaoJie"] = "贾巧姐 的阵亡台词",
}
--[[
	技能：乞巧（限定技）
	描述：准备阶段开始时，若你的手牌数不足7，你可以将手牌补至七张。
]]--
QiQiao = sgs.CreateTriggerSkill{
	name = "hpQiQiao",
	frequency = sgs.Skill_Limited,
	events = {sgs.EventPhaseStart},
	limit_mark = "@hpQiQiaoMark",
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			local num = player:getHandcardNum()
			local delt = 7 - num
			if delt > 0 then
				if player:askForSkillInvoke("hpQiQiao", data) then
					local room = player:getRoom()
					room:broadcastSkillInvoke("hpQiQiao") --播放配音
					room:notifySkillInvoked(player, "hpQiQiao") --显示技能发动
					player:loseMark("@hpQiQiaoMark", 1)
					room:drawCards(player, delt, "hpQiQiao")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target and target:isAlive() and target:hasSkill("hpQiQiao") then
			return target:getMark("@hpQiQiaoMark") > 0
		end
		return false
	end,
}
--添加技能
JiaQiaoJie:addSkill(QiQiao)
--翻译信息
sgs.LoadTranslationTable{
	["hpQiQiao"] = "乞巧",
	[":hpQiQiao"] = "<font color=\"red\"><b>限定技</b></font>，准备阶段开始时，若你的手牌数不足7，你可以将手牌补至七张。",
	["@hpQiQiaoMark"] = "乞巧",
}
--[[
	技能：交缘
	描述：出牌阶段限一次，你可以交给一名其他角色一张牌，然后获得其一张牌。若如此做，你回复1点体力。
]]--
JiaoYuanCard = sgs.CreateSkillCard{
	name = "hpJiaoYuanCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("hpJiaoYuan") --播放配音
		local target = targets[1]
		room:obtainCard(target, self, false)
		if not target:isNude() then
			local id = room:askForCardChosen(source, target, "he", "hpJiaoYuan")
			if id > 0 then
				room:obtainCard(source, id, false)
			end
		end
		if source:getLostHp() > 0 then
			local recover = sgs.RecoverStruct()
			recover.who = source
			recover.recover = 1
			room:recover(source, recover)
		end
	end,
}
JiaoYuan = sgs.CreateViewAsSkill{
	name = "hpJiaoYuan",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = JiaoYuanCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:isNude() then
			return false
		elseif player:hasUsed("#hpJiaoYuanCard") then
			return false
		end
		return true
	end,
}
--添加技能
JiaQiaoJie:addSkill(JiaoYuan)
--翻译信息
sgs.LoadTranslationTable{
	["hpJiaoYuan"] = "交缘",
	[":hpJiaoYuan"] = "<font color=\"green\"><b>出牌阶段限一次</b></font>，你可以交给一名其他角色一张牌，然后获得其一张牌。若如此做，你回复1点体力。",
	["hpjiaoyuan"] = "交缘",
}
--[[****************************************************************
	编号：HPIN - 011
	武将：李纨
	称号：槁情
	势力：蜀
	性别：女
	体力上限：3勾玉
]]--****************************************************************
LiWan = sgs.General(extension, "hpLiWan", "shu", 3, false)
--翻译信息
sgs.LoadTranslationTable{
	["hpLiWan"] = "李纨",
	["&hpLiWan"] = "李纨",
	["#hpLiWan"] = "槁情",
	["designer:hpLiWan"] = "DGAH",
	["cv:hpLiWan"] = "无",
	["illustrator:hpLiWan"] = "网络资源",
	["~hpLiWan"] = "李纨 的阵亡台词",
}
--[[
	技能：稻香
	描述：你可以将一张基本牌当一张基本牌使用或打出。
]]--
function chooseToDaoXiangUse(room, user, suit, point)
	local banpacks = sgs.GetConfig("ban_packages", "")
	local manFlag = not string.find(banpacks, "maneuvering")
	local choices = {}
	if sgs.Slash_IsAvailable(user) then
		local card = sgs.Sanguosha:cloneCard("slash", suit, point)
		card:deleteLater()
		local alives = room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if user:canSlash(p, card) then
				table.insert(choices, "slash")
				if manFlag then
					table.insert(choices, "thunder_slash")
					table.insert(choices, "fire_slash")
				end
				break
			end
		end
	end
	if user:getLostHp() > 0 and not user:hasFlag("Global_PreventPeach") then
		local card = sgs.Sanguosha:cloneCard("peach", suit, point)
		card:deleteLater()
		if not user:isProhibited(user, card) then
			table.insert(choices, "peach")
		end
	end
	if manFlag and sgs.Analeptic_IsAvailable(user) then
		local card = sgs.Sanguosha:cloneCard("analeptic", suit, point)
		card:deleteLater()
		if not user:isProhibited(user, card) then
			table.insert(choices, "analeptic")
		end
	end
	if #choices > 0 then
		choices = table.concat(choices, "+")
		return room:askForChoice(user, "hpDaoXiangChooseToUse", choices)
	end
end
function chooseToDaoXiangResponse(room, user, pattern, suit, point)
	local banpacks = sgs.GetConfig("ban_packages", "")
	local manFlag = not string.find(banpacks, "maneuvering")
	local choices = {}
	local card = sgs.Sanguosha:cloneCard("slash", suit, point)
	card:deleteLater()
	if card:match(pattern) then
		table.insert(choices, "slash")
		if manFlag then
			table.insert(choices, "thunder_slash")
			table.insert(choices, "fire_slash")
		end
	end
	card = sgs.Sanguosha:cloneCard("jink", suit, point)
	card:deleteLater()
	if card:match(pattern) then
		table.insert(choices, "jink")
	end
	card = sgs.Sanguosha:cloneCard("peach", suit, point)
	card:deleteLater()
	if card:match(pattern) and not user:hasFlag("Global_PreventPeach") then
		table.insert(choices, "peach")
	end
	if manFlag then
		card = sgs.Sanguosha:cloneCard("analeptic", suit, point)
		card:deleteLater()
		if card:match(pattern) then
			table.insert(choices, "analeptic")
		end
	end
	if #choices > 0 then
		choices = table.concat(choices, "+")
		return room:askForChoice(user, "hpDaoXiangChooseToResponse", choices)
	end
end
function selectTargets(room, user, name, id, suit, point)
	room:setPlayerProperty(user, "hpDaoXiangCardName", sgs.QVariant(name))
	room:setPlayerMark(user, "hpDaoXiangCardID", id)
	room:setPlayerMark(user, "hpDaoXiangCardSuit", tonumber(suit))
	room:setPlayerMark(user, "hpDaoXiangCardNumber", point)
	local prompt = string.format("@hpDaoXiangSelect:::%s:", name)
	local success = room:askForUseCard(user, "@@hpDaoXiang", prompt)
	if not success then
		room:setPlayerProperty(user, "hpDaoXiangCardName", sgs.QVariant(""))
		room:setPlayerMark(user, "hpDaoXiangCardID", 0)
		room:setPlayerMark(user, "hpDaoXiangCardSuit", 0)
		room:setPlayerMark(user, "hpDaoXiangCardNumber", 0)
	end
end
DaoXiangCard = sgs.CreateSkillCard{
	name = "hpDaoXiangCard",
	target_fixed = true,
	will_throw = true,
	on_validate = function(self, use)
		local user = use.from
		local room = user:getRoom()
		local reason = sgs.Sanguosha:getCurrentCardUseReason()
		local id = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(id)
		local suit = card:getSuit()
		local point = card:getNumber()
		local name = nil
		if reason == _RES_USE then
			local pattern = self:getUserString() or ""
			name = chooseToDaoXiangResponse(room, user, pattern, suit, point)
		else
			name = chooseToDaoXiangUse(room, user, suit, point)
		end
		if name then
			local vs_card = sgs.Sanguosha:cloneCard(name, suit, point)
			if vs_card:targetFixed() then
				vs_card:addSubcard(id)
				vs_card:setSkillName("hpDaoXiang")
				return vs_card
			end
			vs_card:deleteLater()
			if selectTargets(room, user, name, id, suit, point) then
				return self
			end
		end
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local pattern = self:getUserString() or ""
		local reason = sgs.Sanguosha:getCurrentCardUseReason()
		local id = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(id)
		local suit = card:getSuit()
		local point = card:getNumber()
		local name = chooseToDaoXiangResponse(room, user, pattern, suit, point)
		if name then
			local vs_card = sgs.Sanguosha:cloneCard(name, suit, point)
			if vs_card:targetFixed() or reason == _RESPONSE then
				vs_card:addSubcard(id)
				vs_card:setSkillName("hpDaoXiang")
				return vs_card
			end
			vs_card:deleteLater()
			if selectTargets(room, user, name, id, suit, point) then
				return self
			end
		end
	end,
}
function getDXCard(user)
	local name = user:property("hpDaoXiangCardName"):toString()
	local id = user:getMark("hpDaoXiangCardID")
	local suit = user:getMark("hpDaoXiangCardSuit")
	local point = user:getMark("hpDaoXiangCardNumber")
	local vs_card = sgs.Sanguosha:cloneCard(name, suit, point)
	vs_card:addSubcard(id)
	vs_card:setSkillName("hpDaoXiang")
	return vs_card
end
DaoXiangSelectCard = sgs.CreateSkillCard{
	name = "hpDaoXiangSelectCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		local card = getDXCard(sgs.Self)
		local selected = sgs.PlayerList()
		for _,target in ipairs(targets) do
			selected:append(target)
		end
		return card:targetFilter(selected, to_select, sgs.Self)
	end,
	feasible = function(self, targets)
		local card = getDXCard(sgs.Self)
		local selected = sgs.PlayerList()
		for _,target in ipairs(targets) do
			selected:append(target)
		end
		return card:targetsFeasible(selected, sgs.Self)
	end,
	on_validate = function(self, use)
		local user = use.from
		local room = user:getRoom()
		local vs_card = getDXCard(user)
		room:setPlayerProperty(user, "hpDaoXiangCardName", sgs.QVariant(""))
		room:setPlayerMark(user, "hpDaoXiangCardID", 0)
		room:setPlayerMark(user, "hpDaoXiangCardSuit", 0)
		room:setPlayerMark(user, "hpDaoXiangCardNumber", 0)
		return vs_card
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local vs_card = getDXCard(user)
		room:setPlayerProperty(user, "hpDaoXiangCardName", sgs.QVariant(""))
		room:setPlayerMark(user, "hpDaoXiangCardID", 0)
		room:setPlayerMark(user, "hpDaoXiangCardSuit", 0)
		room:setPlayerMark(user, "hpDaoXiangCardNumber", 0)
		return vs_card
	end,
}
DaoXiang = sgs.CreateViewAsSkill{
	name = "hpDaoXiang",
	n = 1,
	ask = "",
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
		if ask == "@@hpDaoXiang" then
			return DaoXiangSelectCard:clone()
		elseif #cards == 1 then
			local card = DaoXiangCard:clone()
			card:addSubcard(cards[1])
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			card:setUserString(pattern)
			return card
		end
	end,
	enabled_at_play = function(self, player)
		ask = ""
		if player:isNude() then
			return false
		elseif sgs.Slash_IsAvailable(player) then
			return true
		elseif sgs.Analeptic_IsAvailable(player) then
			return true
		elseif player:getLostHp() > 0 and not player:hasFlag("Global_PreventPeach") then
			return true
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		ask = pattern
		if pattern == "@@hpDaoXiang" then
			return true
		elseif player:isNude() then
			return false
		elseif string.find(pattern, "slash") then
			return true
		elseif string.find(pattern, "jink") then
			return true
		elseif string.find(pattern, "peach") and not player:hasFlag("Global_PreventPeach") then
			return true
		elseif string.find(pattern, "analeptic") then
			return true
		end
		return false
	end,
}
--添加技能
LiWan:addSkill(DaoXiang)
--翻译信息
sgs.LoadTranslationTable{
	["hpDaoXiang"] = "稻香",
	[":hpDaoXiang"] = "你可以将一张基本牌当一张基本牌使用或打出。",
	["hpDaoXiangChooseToUse"] = "稻香",
	["hpDaoXiangChooseToResponse"] = "稻香",
	["@hpDaoXiangSelect"] = "请为此【%arg】选择必要的目标",
	["~hpDaoXiang"] = "选择一些目标角色->点击“确定”",
}
--[[
	技能：心血
	描述：一名你攻击范围内的角色被指定为【杀】或【决斗】的唯一目标时，你可以令其摸一张牌，然后你代替其成为此【杀】或决斗的目标。若如此做，每当该角色杀死一名角色后，你摸X张牌（X为你的体力且至少为1）。
]]--
XinXue = sgs.CreateTriggerSkill{
	name = "hpXinXue",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetSpecifying, sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecifying then
			local use = data:toCardUse()
			local card = use.card
			if card:isKindOf("Slash") or card:isKindOf("Duel") then
				if use.to:length() == 1 then
					local victim = use.to:first()
					local source = use.from
					local prompt = string.format(
						"invoke:%s:%s:%s:", 
						source and source:objectName() or "", 
						victim:objectName(), 
						card:objectName()
					)
					local alives = room:getAlivePlayers()
					room:setTag("hpXinXueData", data) --For AI
					for _,p in sgs.qlist(alives) do
						if p:hasSkill("hpXinXue") and p:inMyAttackRange(victim) then
							if p:askForSkillInvoke("hpXinXue", sgs.QVariant(prompt)) then
								room:broadcastSkillInvoke("hpXinXue") --播放配音
								room:notifySkillInvoked(p, "hpXinXue") --显示技能发动
								room:drawCards(victim, 1, "hpXinXue")
								room:setPlayerMark(victim, "hpXinXueTarget", 1)
								local mark = string.format("hpXinXueSource:%s", p:objectName())
								room:setPlayerMark(victim, mark, 1)
								if source:isProhibited(p, card) then
									local msg = sgs.LogMessage()
									msg.type = "#hpXinXueCancel"
									msg.from = p
									msg.to:append(victim)
									msg.arg = "hpXinXue"
									msg.arg2 = card:objectName()
									room:sendLog(msg) --发送提示信息
									use.to = sgs.SPlayerList()
									data:setValue(use)
									return true
								else
									local msg = sgs.LogMessage()
									msg.type = "#hpXinXueReplace"
									msg.from = p
									msg.to:append(victim)
									msg.arg = "hpXinXue"
									msg.arg2 = card:objectName()
									room:sendLog(msg) --发送提示信息
									use.to = sgs.SPlayerList()
									use.to:append(p)
									data:setValue(use)
									return false
								end
							end
						end
					end
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			local victim = death.who
			if victim and victim:objectName() == player:objectName() then
				local reason = death.damage
				if reason then
					local killer = reason.from
					if killer and killer:getMark("hpXinXueTarget") > 0 then
						local alives = room:getAlivePlayers()
						for _,source in sgs.qlist(alives) do
							if source:hasSkill("hpXinXue") then
								local mark = string.format("hpXinXueSource:%s", source:objectName())
								if killer:getMark(mark) > 0 then
									local count = source:getHp()
									count = math.max(1, count)
									room:drawCards(source, count, "hpXinXue")
								end
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
--添加技能
LiWan:addSkill(XinXue)
--翻译信息
sgs.LoadTranslationTable{
	["hpXinXue"] = "心血",
	[":hpXinXue"] = "一名你攻击范围内的角色被指定为【杀】或【决斗】的唯一目标时，你可以令其摸一张牌，然后你代替其成为此【杀】或决斗的目标。若如此做，每当该角色杀死一名角色后，你摸X张牌（X为你的体力且至少为1）",
	["hpXinXue:invoke"] = "%src 对 %dest 使用了【%arg】，您想发动技能“心血”代替 %dest 成为此牌的目标吗？",
	["#hpXinXueCancel"] = "%from 对 %to 发动了“%arg”，但自身并不能成为此【%arg2】的目标，改为取消此目标",
	["#hpXinXueReplace"] = "%from 发动了“%arg”，代替 %to 成为了此【%arg2】的目标",
}
--[[****************************************************************
	编号：HPIN - 012
	武将：秦可卿
	称号：孽情
	势力：群
	性别：女
	体力上限：4勾玉
]]--****************************************************************
QinKeQing = sgs.General(extension, "hpQinKeQing", "qun", 4, false)
--翻译信息
sgs.LoadTranslationTable{
	["hpQinKeQing"] = "秦可卿",
	["&hpQinKeQing"] = "秦可卿",
	["#hpQinKeQing"] = "孽情",
	["designer:hpQinKeQing"] = "DGAH",
	["cv:hpQinKeQing"] = "无",
	["illustrator:hpQinKeQing"] = "网络资源",
	["~hpQinKeQing"] = "秦可卿 的阵亡台词",
}
--[[
	技能：迷津
	描述：出牌阶段限一次，你可以令你攻击范围内的一名角色选择一项：交给你一张红心手牌，或者失去1点体力。
]]--
MiJinCard = sgs.CreateSkillCard{
	name = "hpMiJinCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return sgs.Self:inMyAttackRange(to_select)
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("hpMiJin") --播放配音
		room:notifySkillInvoked(source, "hpMiJin") --显示技能发动
		local target = targets[1]
		local data = sgs.QVariant()
		data:setValue(source)
		local prompt = string.format("@hpMiJin:%s:", source:objectName())
		local heart = room:askForCard(target, ".|heart|.|hand", prompt, data, sgs.Card_MethodNone, source, false, "hpMiJin")
		if heart then
			room:obtainCard(source, heart, true)
		else
			room:loseHp(target, 1)
		end
	end,
}
MiJin = sgs.CreateViewAsSkill{
	name = "hpMiJin",
	n = 0,
	view_as = function(self, cards)
		return MiJinCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#hpMiJinCard")
	end,
}
--添加技能
QinKeQing:addSkill(MiJin)
--翻译信息
sgs.LoadTranslationTable{
	["hpMiJin"] = "迷津",
	[":hpMiJin"] = "<font color=\"green\"><b>出牌阶段限一次</b></font>，你可以令你攻击范围内的一名角色选择一项：交给你一张红心手牌，或者失去1点体力。",
	["@hpMiJin"] = "迷津：请交给 %src 一张红心手牌，否则你将失去 1 点体力",
	["hpmijin"] = "迷津",
}
--[[
	技能：托梦
	描述：你死亡时，你可以令一名角色观看牌堆顶的五张牌并将之以任意次序置于牌堆顶，然后该角色进行一次判定。若结果为【闪】，其与其攻击范围内的所有角色依次回复1点体力；若不为【闪】，其与其攻击范围内的所有角色依次失去1点体力上限。
]]--
TuoMeng = sgs.CreateTriggerSkill{
	name = "hpTuoMeng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local victim = death.who
		if victim and victim:objectName() == player:objectName() then
			local room = player:getRoom()
			local alives = room:getAlivePlayers()
			local target = room:askForPlayerChosen(player, alives, "hpTuoMeng", "@hpTuoMeng", true, true)
			if target then
				room:broadcastSkillInvoke("hpTuoMeng") --播放配音
				room:notifySkillInvoked(player, "hpTuoMeng") --显示技能发动
				local card_ids = room:getNCards(5)
				room:askForGuanxing(target, card_ids, sgs.Room_GuanxingUpOnly)
				local judge = sgs.JudgeStruct()
				judge.who = target
				judge.reason = "hpTuoMeng"
				judge.pattern = "Jink"
				judge.good = true
				room:judge(judge)
				local players = sgs.SPlayerList()
				players:append(target)
				for _,p in sgs.qlist(alives) do
					if target:inMyAttackRange(p) then
						players:append(p)
					end
				end
				if judge:isGood() then
					for _,p in sgs.qlist(players) do
						if p:isAlive() and p:getLostHp() > 0 then
							local recover = sgs.RecoverStruct()
							recover.who = player
							recover.recover = 1
							room:recover(p, recover, true)
						end
					end
				else
					for _,p in sgs.qlist(players) do
						if p:isAlive() then
							room:loseMaxHp(p, 1)
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill("hpTuoMeng")
	end,
}
--添加技能
QinKeQing:addSkill(TuoMeng)
--翻译信息
sgs.LoadTranslationTable{
	["hpTuoMeng"] = "托梦",
	[":hpTuoMeng"] = "你死亡时，你可以令一名角色观看牌堆顶的五张牌并将之以任意次序置于牌堆顶，然后该角色进行一次判定。若结果为【闪】，该角色与其攻击范围内的所有角色依次回复1点体力；若不为【闪】，该角色与其攻击范围内的所有角色依次失去1点体力上限。",
	["@hpTuoMeng"] = "您可以选择一名角色发动“托梦”",
}