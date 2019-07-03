--[[
	太阳神三国杀武将扩展包·金陵十二钗（AI部分）
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
]]--
--[[****************************************************************
	编号：HPIN - 001
	武将：林黛玉
	称号：情情
	势力：魏
	性别：女
	体力上限：3勾玉
]]--****************************************************************
--[[
	技能：葬花
	描述：出牌阶段限一次，你可以将一张方块或草花牌置于牌堆底，然后你选择一项：1、令你攻击范围内的一名角色失去1点体力；2、摸两张牌。
]]--
--room:askForGuanxing(source, ids, sgs.Room_GuanxingDownOnly)
--room:askForChoice(source, "hpZangHua", choices)
sgs.ai_skill_choice["hpZangHua"] = function(self, choices, data)
	local choice = sgs.ai_zanghua_choice
	if choice then
		sgs.ai_zanghua_choice = nil
		return choice
	end
	return "draw"
end
--room:askForPlayerChosen(source, victims, "hpZangHua", "@hpZangHua", false)
sgs.ai_skill_playerchosen["hpZangHua"] = function(self, targets)
	local friends, unknowns, enemies = {}, {}, {}
	for _,target in sgs.qlist(targets) do
		if self:isFriend(target) then
			table.insert(friends, target)
		elseif self:isEnemy(target) then
			table.insert(enemies, target)
		else
			table.insert(unknowns, target)
		end
	end
	if #enemies > 0 then
		self:sort(enemies, "defense")
		for _,enemy in ipairs(enemies) do
			if self:needToLoseHp(enemy) or enemy:hasSkill("zhaxiang") then
			else
				return enemy
			end
		end
	end
	if #friends > 0 then
		self:sort(friends, "defense")
		friends = sgs.reverse(friends)
		for _,friend in ipairs(friends) do
			if self:isWeak(friend) or friend:getHp() <= 1 then
			elseif self:needToLoseHp(friend) or friend:hasSkill("zhaxiang") then
				return friend
			end
		end
	end
	if #unknowns > 0 then
		self:sort(unknowns, "threat")
		return unknowns[1]
	end
	if #enemies > 0 then
		self:sort(enemies, "hp")
		return enemies[1]
	end
end
--ZangHuaCard:Play
local zanghua_skill = {
	name = "hpZangHua",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#hpZangHuaCard") then
			return nil
		elseif self.player:isNude() then
			return nil
		end
		return sgs.Card_Parse("#hpZangHuaCard:.:")
	end,
}
table.insert(sgs.ai_skills, zanghua_skill)
sgs.ai_skill_use_func["#hpZangHuaCard"] = function(card, use, self)
	local to_use, target = nil, nil
	local armor = self.player:getArmor()
	if armor and self:needToThrowArmor() then
		local suit = armor:getSuit()
		if suit == sgs.Card_Club or suit == sgs.Card_Diamond then
			to_use = armor
		end
	end
	if not to_use then
		local handcards = self.player:getHandcards()
		local can_use = {}
		for _,c in sgs.qlist(handcards) do
			local suit = c:getSuit()
			if suit == sgs.Card_Club or suit == sgs.Card_Diamond then
				table.insert(can_use, c)
			end
		end
		if #can_use > 0 then
			self:sortByUseValue(can_use, true)
			local peachNum = self:getCardsNum("Peach", "he", true)
			for _,c in ipairs(can_use) do
				if c:isKindOf("ExNihilo") then
				elseif c:isKindOf("Peach") and peachNum < 2 then
				else
					to_use = c
					break
				end
			end
		end
	end
	if not to_use then
		local equips = self.player:getEquips()
		local can_use = {}
		for _,equip in sgs.qlist(equips) do
			local suit = equip:getSuit()
			if suit == sgs.Card_Club or suit == sgs.Card_Diamond then
				table.insert(can_use, equip)
			end
		end
		if #can_use > 0 then
			self:sortByKeepValue(can_use)
			for _,equip in ipairs(can_use) do
				if equip:isKindOf("Weapon") then
					for _,enemy in ipairs(enemies) do
						if self.player:distanceTo(enemy) <= self.player:getAttackRange(false) then
							target = enemy
							to_use = equip
							break
						end
					end
				elseif equip:isKindOf("OffensiveHorse") then
					for _,enemy in ipairs(enemmies) do
						if self.player:inMyAttackRange(enemy, 1) then
							target = enemy
							to_use = equip
							break
						end
					end
				elseif equip:isKindOf("Treasure") then
					if equip:isKindOf("WoodenOx") then
						local pile = self.player:getPile("wooden_ox")
						if pile:length() <= 1 then
							to_use = equip
							break
						end
					else
						to_use = equip
						break
					end
				elseif equip:isKindOf("DefensiveHorse") then
					if not self:isWeak() then
						to_use = equip
						break
					end
				elseif equip:isKindOf("Armor") then
					if not self:isWeak() then
						to_use = equip
					end
				end
				if to_use then
					break
				end
			end
		end
	end
	if to_use then
		if target then
			if self:isWeak() then
				target = nil
			end
		else
			if self:getOverflow() >= 0 then
				for _,enemy in ipairs(self.enemies) do
					if self.player:inMyAttackRange(enemy) then
						if not enemy:hasSkill("zhaxiang") then
							target = enemy
							break
						end
					end
				end
			end
			if not target then
				for _,enemy in ipairs(self.enemies) do
					if enemy:getHp() <= 1 then
						target = enemy
						break
					end
				end
			end
		end
	end
	if to_use then
		local card_str = "#hpZangHuaCard:"..to_use:getEffectiveId()..":"
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if target then
			sgs.ai_zanghua_choice = "lose"
		else
			sgs.ai_zanghua_choice = "draw"
		end
	end
end
--相关信息
sgs.ai_use_value["hpZangHuaCard"] = 3.8
sgs.ai_use_priority["hpZangHuaCard"] = 1.7
--[[
	技能：还泪
	描述：你每受到1点伤害，获得一枚“泪”标记。
		你濒死时，你可以弃置所有的“泪”标记并令一名其他角色摸等量的牌，然后该角色增加1点体力上限并回复1点体力。若如此做，你进行一次判定，若结果为红心【桃】，你回复所有体力，否则你立即死亡。
]]--
--room:askForPlayerChosen(player, others, "hpHuanLei", prompt, true, true)
sgs.ai_skill_playerchosen["hpHuanLei"] = function(self, targets)
	local hp = self.player:getHp()
	local need = 1 - hp
	local peach = self:getAllPeachNum()
	if need <= peach then
		return
	end
	if self.role == "loyalist" then
		local lord = self.room:getLord()
		if lord and self:isFriend(lord) then
			return lord
		end
	end
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends, p)
		end
	end
	if #friends > 0 then
		self:sort(friends, "threat")
		return friends[1]
	end
	if math.random(1, 100) <= 30 then
		local players = sgs.QList2Table(targets)
		self:sort(players, "defense")
		return players[1]
	end
end
--[[****************************************************************
	编号：HPIN - 002
	武将：薛宝钗
	称号：无情
	势力：吴
	性别：女
	体力上限：3勾玉
]]--****************************************************************
--[[
	技能：锁玉
	描述：一名角色的摸牌阶段开始时，你可以摸一张牌，然后交给其一张牌。若如此做，你不能再次发动“锁玉”直到你的下个回合开始，且该角色摸牌阶段摸牌时少摸一张牌。
]]--
--source:askForSkillInvoke("hpSuoYu", sgs.QVariant(prompt))
sgs.ai_skill_invoke["hpSuoYu"] = function(self, data)
	local current = self.room:getCurrent()
	if current then
		if current:objectName() == self.player:objectName() then
			local armor = self.player:getArmor()
			if armor and self:needToThrowArmor() then
				return true
			elseif self.player:hasEquip() and self:hasSkills(sgs.lose_equip_skill) then
				return true
			end
		elseif self.room:alivePlayerCount() == 2 then
			if not current:hasSkill("manjuan") then
				return true
			end
		elseif self:isFriend(current) then
			local cards = self.player:getCards("he")
			if not self:hasCrossbowEffect(current) then
				local crossbow = nil
				for _,c in sgs.qlist(cards) do
					if c:isKindOf("Crossbow") or c:isKindOf("VSCrossbow") then
						crossbow = c
						break
					end
				end
				if crossbow then
					local need_crossbow = false
					if current:hasSkill("noskurou") and current:getHp() > 2 then
						need_crossbow = true
					elseif current:getHandcardNum() >= 20 then
						need_crossbow = true
					elseif getCardsNum("Slash", current, self.player) > 2 then
						need_crossbow = true
					end
					if need_crossbow then
						sgs.ai_suoyu_id = crossbow:getEffectiveId()
						return true
					end
				end
			end
		elseif self:isEnemy(current) then
			local handcards = self.player:getHandcards()
			for _,c in sgs.qlist(handcards) do
				if c:isKindOf("Disaster") then
					sgs.ai_suoyu_id = c:getEffectiveId()
					return true
				elseif c:isKindOf("Collateral") or c:isKindOf("AmazingGrace") then
					sgs.ai_suoyu_id = c:getEffectiveId()
					return true
				end
			end
		end
	end
	return false
end
--room:askForCard(source, "..!", hint, ai_data, sgs.Card_MethodNone, player, false, "hpSuoYu", false)
sgs.ai_skill_cardask["@hpSuoYu"] = function(self, data, pattern, target, target2, arg, arg2)
	local cards = self.player:getCards("he")
	local id = sgs.ai_suoyu_id
	if id then
		sgs.ai_suoyu_id = nil
		for _,c in sgs.qlist(cards) do
			if c:getEffectiveId() == id then
				return "$"..id
			end
		end
	end
	if self:isFriend(target) then
		local armor = self.player:getArmor()
		if armor and self:needToThrowArmor() then
			return "$"..armor:getEffectiveId()
		end
		cards = sgs.QList2Table(cards)
		if self:isWeak(friend) then
			self:sortByKeepValue(cards, true)
		else
			self:sortByUseValue(cards)
		end
		return "$"..cards[1]:getEffectiveId()
	else
		cards = sgs.QList2Table(cards)
		self:sortByUseValue(cards, true)
		return "$"..cards[1]:getEffectiveId()
	end
end
--[[
	技能：空闺
	描述：当你需要使用或打出一张基本牌或非延时性锦囊牌时，若你没有手牌，你可以视为使用或打出了此牌。每名角色的回合限一次。
]]--
--room:askForChoice(source, "hpKongGuiChooseToUse", choices)
sgs.ai_skill_choice["hpKongGuiChooseToUse"] = function(self, choices, data)
	if string.find(choices, "peach") then
		if self.player:getHp() < getBestHp(self.player) then
			return "peach"
		end
	end
	local items = choices:split("+")
	local can_use = {}
	for _,item in ipairs(items) do
		local card = sgs.Sanguosha:cloneCard(item)
		card:deleteLater()
		local dummy_use = {
			isDummy = true,
		}
		if card:isKindOf("TrickCard") then
			self:useTrickCard(card, dummy_use)
		else
			self:useBasicCard(card, dummy_use)
		end
		if dummy_use.card then
			table.insert(can_use, item)
		end
	end
	if #can_use > 0 then
		return can_use[math.random(1, #can_use)]
	end
end
--room:askForChoice(source, "hpKongGuiChooseToResponse", choices)
sgs.ai_skill_choice["hpKongGuiChooseToResponse"] = function(self, choices, data)
	local items = choices:split("+")
	if #items == 1 then
		return items[1]
	end
	if string.find(choices, "analeptic") then
		return "analeptic"
	end
	return items[math.random(1, #items)]
end
--room:askForUseCard(source, "@@hpKongGui", prompt)
sgs.ai_skill_use["@@hpKongGui"] = function(self, prompt, method)
	local name = self.player:property("hpKongGuiCardType"):toString()
	local card = sgs.Sanguosha:cloneCard(name)
	if card then
		card:deleteLater()
		local dummy_use = {
			isDummy = true,
			to = sgs.SPlayerList(),
		}
		if card:isKindOf("BasicCard") then
			self:useBasicCard(card, dummy_use)
		elseif card:isKindOf("TrickCard") then
			self:useTrickCard(card, dummy_use)
		end
		local targets = {}
		for _,target in sgs.qlist(dummy_use.to) do
			table.insert(targets, target:objectName())
		end
		return "#hpKongGuiSelectCard:.:->"..table.concat(targets, "+")
	end
	return "."
end
--KongGuiCard:Play
local konggui_skill = {
	name = "hpKongGui",
	getTurnUseCard = function(self, inclusive)
		if self.player:isKongcheng() and self.player:getMark("hpKongGuiInvoked") == 0 then
			return sgs.Card_Parse("#hpKongGuiCard:.:")
		end
	end,
}
table.insert(sgs.ai_skills, konggui_skill)
sgs.ai_skill_use_func["#hpKongGuiCard"] = function(card, use, self)
	use.card = card
end
--KongGuiCard:Response
sgs.ai_cardsview_valuable["hpKongGui"] = function(self, class_name, player)
	if player:isKongcheng() and player:getMark("hpKongGuiInvoked") == 0 then
		if class_name == "Slash" then
			return "#hpKongGuiCard:.:slash"
		elseif class_name == "Jink" then
			return "#hpKongGuiCard:.:jink"
		elseif class_name == "Peach" then
			return "#hpKongGuiCard:.:peach"
		elseif class_name == "Analeptic" then
			return "#hpKongGuiCard:.:analeptic"
		elseif class_name == "Nullification" then
			return "#hpKongGuiCard:.:nullification"
		end
	end
end
--player:askForSkillInvoke("hpKongGui", data)
sgs.ai_skill_invoke["hpKongGui"] = function(self, data)
	return true
end
--相关信息
sgs.ai_use_value["hpKongGuiCard"] = 4
sgs.ai_use_priority["hpKongGuiCard"] = 0.5
--[[****************************************************************
	编号：HPIN - 003
	武将：贾元春
	称号：尊情
	势力：蜀
	性别：女
	体力上限：3勾玉
]]--****************************************************************
--[[
	技能：省亲
	描述：你或你攻击范围内的一名角色的回合开始时，若你的武将牌正面向上，你可以令其摸两张牌。若如此做，回合结束时，其受到X点伤害（X为其弃牌阶段弃置牌的数目）
]]--
--source:askForSkillInvoke("hpXingQin", sgs.QVariant(prompt))
sgs.ai_skill_invoke["hpXingQin"] = function(self, data)
	if self.player:hasSkill("hpGongHen") then
		if self.player:getMark("hpXingQinTimes") == 3 then
			return false
		end
	end
	local current = self.room:getCurrent()
	if current then
		local num = current:getHandcardNum()
		local keep = current:getMaxCards()
		local skills = current:getVisibleSkillList(true)
		local draw = self:ImitateResult_DrawNCards(current, skills) + 2
		local space = keep - num - draw
		if self:isFriend(current) then
			if self:hasSkills("qiaobian|keji", current) then
				return true
			elseif current:hasSkill("conghui") and num < 9 then
				return true
			elseif space > 0 then
				return true
			elseif self:willSkipPlayPhase(current) then
				return false
			end
			return space > -2
		elseif self:isEnemy(current) then
			if self:hasSkills("qiaobian|keji", current) then
				return false
			elseif current:hasSkill("conghui") and num < 9 then
				return false
			elseif space > 0 then
				return false
			elseif self:willSkipPlayPhase(current) then
				return true
			end
			return space < -2
		end
	end
	return false
end
--[[
	技能：宫恨（锁定技）
	描述：一名角色的回合结束后，若你于该回合内对其发动过“省亲”，你执行第X项：1、不能使用或打出红色牌直到你的下回合开始；2、失去1点体力；3、摸一张牌并翻面；4、立即死亡。（X为你上回合结束后已发动“省亲”的次数且至多为4）
]]--
--[[****************************************************************
	编号：HPIN - 004
	武将：贾探春
	称号：敏情
	势力：魏
	性别：女
	体力上限：3勾玉
]]--****************************************************************
--[[
	技能：结社
	描述：出牌阶段限一次，若你有手牌，你可以选择至少一名有手牌的其他角色，你与这些角色同时打出一张手牌。打出牌点数最大者若唯一，其摸一张牌，然后其可以从所有参与打出牌的角色中选择任意数目的角色，令这些角色各摸一张牌。
]]--
--room:askForCard(target, ".!", prompt, data, sgs.Card_MethodPindian, nil, false, "hpJieShe", true)
--room:askForPlayerChosen(winner, can_draw, "hpJieShe", prompt, true)
sgs.ai_skill_playerchosen["hpJieShe"] = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			if hasManjuanEffect(p) then
			elseif self:needKongcheng(p, true) and self:isWeak(p) then
			else
				return p
			end
		end
	end
end
--JieSheCard:Play
local jieshe_skill = {
	name = "hpJieShe",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#hpJieSheCard") then
			return nil
		elseif self.player:isKongcheng() then
			return nil
		end
		return sgs.Card_Parse("#hpJieSheCard:.:")
	end,
}
table.insert(sgs.ai_skills, jieshe_skill)
sgs.ai_skill_use_func["#hpJieSheCard"] = function(card, use, self)
	local match_max = {}
	local max_card = {}
	local all_known = {}
	local dont_known = {}
	local my_max_card = nil
	local my_max_point = -1
	local handcards = self.player:getHandcards()
	handcards = sgs.QList2Table(handcards)
	self:sortByUseValue(handcards, true)
	for _,c in ipairs(handcards) do
		local point = c:getNumber()
		if point > my_max_point then
			my_max_point = point
			my_max_card = c
		end
	end
	match_max[self.player:objectName()] = my_max_point
	max_card[self.player:objectName()] = my_max_card
	all_known[self.player:objectName()] = true
	dont_known[self.player:objectName()] = false
	local others = self.room:getOtherPlayers(self.player)
	local friends, enemies = {}, {}
	local friend_max_point = my_max_point
	local enemy_max_point = -1
	for _,p in sgs.qlist(others) do
		if not p:isKongcheng() then
			local flag = string.format("visible_%s_%s", self.player:objectName(), p:objectName())
			local p_handcards = p:getHandcards()
			local p_max_card = nil
			local p_max_point = -1
			local all_known_flag = true
			local isFriend = self:isFriend(p)
			for _,c in sgs.qlist(p_handcards) do
				if c:hasFlag("visible") or c:hasFlag(flag) then
					local point = c:getNumber()
					if point > p_max_point then
						p_max_point = point
						p_max_card = c
					end
				else
					all_known_flag = false
				end
			end
			if p_max_card then
				match_max[p:objectName()] = p_max_point
				if isFriend then
					if p_max_point > friend_max_point then
						friend_max_point = p_max_point
					end
				else
					if p_max_point > enemy_max_point then
						enemy_max_point = p_max_point
					end
				end
			else
				match_max[p:objectName()] = isFriend and 1 or 13
				dont_known[p:objectName()] = true
			end
			max_card[p:objectName()] = p_max_card
			all_known[p:objectName()] = all_known_flag
			if isFriend then
				table.insert(friends, p)
			else
				table.insert(enemies, p)
			end
		end
	end
	local to_use = nil
	local targets = {}
	for _,friend in ipairs(friends) do
		local add_flag = true
		if all_known[friend:objectName()] then
			add_flag = false
			local handcards = friend:getHandcards()
			for _,c in sgs.qlist(handcards) do
				if c:isKindOf("Peach") or c:isKindOf("ExNihilo") then
				elseif c:isKindOf("Analeptic") and self:isWeak(friend) then
				else
					add_flag = true
					break
				end
			end
		end
		if add_flag then
			table.insert(targets, friend)
		end
	end
	for _,enemy in ipairs(enemies) do
		local point = match_max[enemy:objectName()] or 13
		if point < friend_max_point then
			table.insert(targets, enemy)
		elseif dont_known[enemy:objectName()] and friend_max_point > 10 then
			table.insert(targets, enemy)
		end
	end
	if #targets == 0 then
		return 
	end
	if friend_max_point == my_max_card:getNumber() then
		to_use = my_max_card:getEffectiveId()
	else
		to_use = handcards[1]:getEffectiveId()
	end
	local card_str = "#hpJieSheCard:"..to_use..":"
	local acard = sgs.Card_Parse(card_str)
	use.card = acard
	if use.to then
		for _,p in ipairs(targets) do
			use.to:append(p)
		end
	end
end
--相关信息
sgs.ai_use_value["hpJieSheCard"] = 2.5
sgs.ai_use_priority["hpJieSheCard"] = 6.8
--[[
	技能：变革
	描述：一名与你距离为1以内的角色的出牌阶段开始时，你可以令其摸X张牌。若如此做，当前出牌阶段结束时，该角色弃X张牌（X为其已损失的体力）
]]--
--source:askForSkillInvoke("hpBianGe", sgs.QVariant(prompt))
sgs.ai_skill_invoke["hpBianGe"] = function(self, data)
	local current = self.room:getCurrent()
	return current and self:isFriend(current)
end
--room:askForDiscard(player, "hpBianGe", x, x, false, true, prompt)
--[[****************************************************************
	编号：HPIN - 005
	武将：史湘云
	称号：憨情
	势力：蜀
	性别：女
	体力上限：4勾玉
]]--****************************************************************
--[[
	技能：醉石
	描述：你使用一张【酒】时，可以摸三张牌。
]]--
--player:askForSkillInvoke("hpZuiShi", data)
sgs.ai_skill_invoke["hpZuiShi"] = true
--[[
	技能：性情
	描述：出牌阶段限一次，你可以选择一项：
		1、弃置一张基本牌，视为对一名其他角色使用了一张【杀】。
		2、弃置一张锦囊牌，令一名角色摸两张牌。
		3、弃置一张装备牌，弃置场上至多两张牌。
		4、对自己造成1点伤害，视为使用了一张【酒】。
]]--
--room:askForCardChosen(source, target, "ej", "hpXingQing")
--room:askForPlayerChosen(source, victims, "hpXingQing", "@hpXingQing", true)
sgs.ai_skill_playerchosen["hpXingQing"] = function(self, targets)
	return self:findPlayerToDiscard("ej", true, true, targets, false)
end
--room:askForCardChosen(source, victim, "ej", "hpXingQing")
--XingQingCard:Play
local xingqing_skill = {
	name = "hpXingQing",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#hpXingQingCard") then
			return nil
		elseif self.player:hasUsed("#hpXingQingBasicCard") then
			return nil
		elseif self.player:hasUsed("#hpXingQingTrickCard") then
			return nil
		elseif self.player:hasUsed("#hpXingQingEquipCard") then
			return nil
		elseif sgs.Analeptic_IsAvailable(self.player) then
			return sgs.Card_Parse("#hpXingQingCard:.:")
		end
	end,
}
table.insert(sgs.ai_skills, xingqing_skill)
sgs.ai_skill_use_func["#hpXingQingCard"] = function(card, use, self)
	if self.player:hasSkill("hpZuiShi") then
		if self.player:hasSkill("hpRuMu") and self.player:getMark("hpRuMuVictim") == 0 then
			use.card = card
		elseif not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, self.player) then
			use.card = card
		elseif self:needToLoseHp() then
			use.card = card
		elseif self.player:getHp() > getBestHp(self.player) then
			use.card = card
		elseif self:getCardsNum("Peach") > 0 then
			use.card = card
		end
	elseif self:getCardsNum("Analeptic") == 0 then
		local needAnal = false
		local dummy_use = {
			isDummy = true,
		}
		local analeptic = sgs.Sanguosha:cloneCard("analeptic")
		self:useBasicCard(analeptic, dummy_use)
		if dummy_use.card and dummy_use.card:isKindOf("Analeptic") then
			needAnal = true
		end
		if needAnal then
			if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, self.player) then
				if self.player:getHp() <= 1 and self:getAllPeachNum() == 0 then
					return 
				elseif self:needToLoseHp() then
					use.card = card
				elseif self:isWeak() then
					return 
				elseif self:getOverflow() < 0 then
					use.card = card
				end
			else
				use.card = card
			end
		end
	end
end
--XingQingBasicCard:Play
local xingqing_basic_skill = {
	name = "hpXingQing",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#hpXingQingCard") then
			return nil
		elseif self.player:hasUsed("#hpXingQingBasicCard") then
			return nil
		elseif self.player:hasUsed("#hpXingQingTrickCard") then
			return nil
		elseif self.player:hasUsed("#hpXingQingEquipCard") then
			return nil
		elseif self.player:isNude() then
			return false
		elseif self.player:canDiscard(self.player, "he") then
			return sgs.Card_Parse("#hpXingQingBasicCard:.:")
		end
	end,
}
table.insert(sgs.ai_skills, xingqing_basic_skill)
sgs.ai_skill_use_func["#hpXingQingBasicCard"] = function(card, use, self)
	local handcards = self.player:getHandcards()
	local basics = {}
	local extra = sgs.Slash_IsAvailable(self.player)
	for _,c in sgs.qlist(handcards) do
		if extra and c:isKindOf("Slash") then
		elseif c:isKindOf("BasicCard") then
			table.insert(basics, c)
		end
	end
	if #basics == 0 then
		return 
	end
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	local dummy_use = {
		isDummy = true,
		to = sgs.SPlayerList(),
	}
	self:useBasicCard(slash, dummy_use)
	if dummy_use.card and dummy_use.card:isKindOf("Slash") and not dummy_use.to:isEmpty() then
		self:sortByKeepValue(basics)
		local card_str = "#hpXingQingBasicCard:"..basics[1]:getEffectiveId()..":"
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then
			local target = dummy_use.to:first()
			use.to:append(target)
		end
	end
end
--XingQingTrickCard:Play
local xingqing_trick_skill = {
	name = "hpXingQing",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#hpXingQingCard") then
			return nil
		elseif self.player:hasUsed("#hpXingQingBasicCard") then
			return nil
		elseif self.player:hasUsed("#hpXingQingTrickCard") then
			return nil
		elseif self.player:hasUsed("#hpXingQingEquipCard") then
			return nil
		elseif self.player:isNude() then
			return false
		elseif self.player:canDiscard(self.player, "he") then
			return sgs.Card_Parse("#hpXingQingTrickCard:.:")
		end
	end,
}
table.insert(sgs.ai_skills, xingqing_trick_skill)
sgs.ai_skill_use_func["#hpXingQingTrickCard"] = function(card, use, self)
	local handcards = self.player:getHandcards()
	local tricks = {}
	for _,c in sgs.qlist(handcards) do
		if c:isKindOf("TrickCard") then
			table.insert(tricks, c)
		end
	end
	if #tricks == 0 then
		return
	end
	local target = self:findPlayerToDraw(true, 2)
	if target then
		self:sortByUseValue(tricks, true)
		local to_use = nil
		for _,c in ipairs(tricks) do
			local dummy_use = {
				isDummy = true,
			}
			self:useTrickCard(c, dummy_use)
			if not dummy_use.card then
				to_use = c
				break
			end
		end
		if to_use then
			local card_str = "#hpXingQingTrickCard:"..to_use:getEffectiveId()..":"
			local acard = sgs.Card_Parse(card_str)
			use.card = acard
			if use.to then
				use.to:append(target)
			end
		end
	end
end
--XingQingEquipCard:Play
local xingqing_equip_skill = {
	name = "hpXingQing",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#hpXingQingCard") then
			return nil
		elseif self.player:hasUsed("#hpXingQingBasicCard") then
			return nil
		elseif self.player:hasUsed("#hpXingQingTrickCard") then
			return nil
		elseif self.player:hasUsed("#hpXingQingEquipCard") then
			return nil
		elseif self.player:isNude() then
			return false
		elseif self.player:canDiscard(self.player, "he") then
			return sgs.Card_Parse("#hpXingQingEquipCard:.:")
		end
	end,
}
table.insert(sgs.ai_skills, xingqing_equip_skill)
sgs.ai_skill_use_func["#hpXingQingEquipCard"] = function(card, use, self)
	local cards = self.player:getCards("he")
	local equips = {}
	for _,c in sgs.qlist(cards) do
		if c:isKindOf("EquipCard") then
			table.insert(equips, c)
		end
	end
	if #equips == 0 then
		return 
	end
	local targets = self:findPlayerToDiscard("he", true, true, nil, true)
	if #targets == 0 then
		return
	end
	self:sortByKeepValue(equips)
	local to_use, targetA, targetB = equips[1], targets[1], nil
	if #targets > 1 then
		targetB = targets[2]
	end
	local id = to_use:getEffectiveId()
	local keepValue = self:getKeepValue(to_use)
	if keepValue > 3 then
		return
	elseif self.room:getCardPlace(id) == sgs.Player_PlaceEquip and self.player:getCards("ej"):length() == 1 then
		if targetA:objectName() == self.player:objectName() then
			targetA, targetB = targetB, nil
		elseif targetB and targetB:objectName() == self.player:objectName() then
			targetB = nil
		end
	end
	if targetA then
		local card_str = "#hpXingQingEquipCard:"..id..":"
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(targetA)
			if targetB then
				use.to:append(targetB)
			end
		end
	end
end
--相关信息
sgs.ai_use_value["hpXingQingCard"] = sgs.ai_use_value["Analeptic"]
sgs.ai_use_priority["hpXingQingCard"] = sgs.ai_use_priority["Analeptic"]
sgs.ai_use_value["hpXingQingBasicCard"] = sgs.ai_use_value["Slash"]
sgs.ai_use_priority["hpXingQingBasicCard"] = sgs.ai_use_priority["Slash"]
sgs.ai_use_value["hpXingQingTrickCard"] = sgs.ai_use_value["ExNihilo"]
sgs.ai_use_priority["hpXingQingTrickCard"] = sgs.ai_use_priority["ExNihilo"]
sgs.ai_card_intention["hpXingQingTrickCard"] = -40
sgs.ai_use_value["hpXingQingEquipCard"] = sgs.ai_use_value["Dismantlement"]
sgs.ai_use_priority["hpXingQingEquipCard"] = sgs.ai_use_priority["Dismantlement"]
--[[****************************************************************
	编号：HPIN - 006
	武将：妙玉
	称号：隐情
	势力：群
	性别：女
	体力上限：3勾玉
]]--****************************************************************
--[[
	技能：梅雪
	描述：准备阶段开始时，你可以观看牌堆顶的X张牌，然后你可以将其中一张非黑桃牌交给一名角色，将其余的牌以任意次序置于牌堆顶（X为你的体力且至少为1、至多为5）。若该角色不为你，回合结束时，你摸一张牌。
]]--
--player:askForSkillInvoke("hpMeiXue", data)
sgs.ai_skill_invoke["hpMeiXue"] = true
--room:askForAG(player, can_give, true, "hpMeiXue")
sgs.ai_skill_askforag["hpMeiXue"] = function(self, card_ids)
	local cards = {}
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		table.insert(cards, card)
	end
	local judges = self.player:getJudgingArea()
	if judges:isEmpty() or self.player:containsTrick("YanxiaoCard") then
	else
		self:sortByUseValue(cards, true)
		local fear_lightning = true
		if self.player:containsTrick("lightning") then
			if self.player:hasSkill("hongyan") then
				fear_lightning = false
			elseif not self:damageIsEffective(self.player, sgs.DamageStruct_Thunder) then
				fear_lightning = false
			end
		end
		for _,judge in sgs.qlist(judges) do
			if judge:isKindOf("Indulgence") then
				for index, card in ipairs(cards) do
					if card:getSuit() == sgs.Card_Heart then
						table.remove(cards, index)
						break
					end
				end
			elseif judge:isKindOf("SupplyShortage") then
				for index, card in ipairs(cards) do
					if card:getSuit() == sgs.Card_Club then
						table.remove(cards, index)
						break
					end
				end
			elseif judge:isKindOf("Lightning") then
				if fear_lightning and #cards > 0 then
					table.remove(cards, 1)
				end
			end
			if #cards == 0 then
				break
			end
		end
	end
	if #cards == 0 then
		return -1
	end
	local to_give, target = self:getCardNeedPlayer(cards, true)
	if to_give and target then
		sgs.ai_meixue_target = target:objectName()
		return to_give:getEffectiveId()
	end
	return -1
end
--room:askForPlayerChosen(player, alives, "hpMeiXue", prompt, true)
sgs.ai_skill_playerchosen["hpMeiXue"] = function(self, targets)
	local name = sgs.ai_meixue_target
	if name then
		sgs.ai_meixue_target = nil
		for _,p in sgs.qlist(targets) do
			if p:objectName() == name then
				return p
			end
		end
	end
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and not hasManjuanEffect(p) then
			table.insert(friends, p)
		end
	end
	local id = self.player:getTag("hpMeiXueCardID"):toInt()
	if id >= 0 and #friends > 0 then
		local card = sgs.Sanguosha:getCard(id)
		local cards = { card }
		local to_give, target = self:getCardNeedPlayer(cards, friends)
		if to_give and target then
			return target
		end
	end
end
--room:askForGuanxing(player, card_ids, sgs.Room_GuanxingUpOnly)
--[[
	技能：劫数（锁定技）
	描述：你受到【南蛮入侵】造成的伤害+1；以你为目标的【南蛮入侵】结算完成后，你摸两张牌。
]]--
--[[****************************************************************
	编号：HPIN - 007
	武将：贾迎春
	称号：懦情
	势力：魏
	性别：女
	体力上限：3勾玉
]]--****************************************************************
--[[
	技能：如木（锁定技）
	描述：每当你于一名角色的回合内受到伤害时，若为你本回合第一次受到伤害，你防止之；每当你于出牌阶段内造成伤害时，若为你本阶段第一次造成伤害，你防止之并摸两张牌。
]]--
--[[
	技能：忍辱（锁定技）
	描述：你的【无懈可击】视为【铁索连环】。
]]--
--[[****************************************************************
	编号：HPIN - 008
	武将：贾惜春
	称号：冷情
	势力：群
	性别：女
	体力上限：3勾玉
]]--****************************************************************
--[[
	技能：冷绝
	描述：一名角色对你攻击范围内的另一名角色使用【桃】时，你可以弃一张手牌，令此【桃】对目标角色无效。
]]--
--room:askForCard(p, ".", prompt, data, "hpLengJue")
sgs.ai_skill_cardask["@hpLengJue"] = function(self, data, pattern, target, target2, arg, arg2)
	if target2 and self:isEnemy(target2) then
		if self.role == "renegade" and target2:isLord() and self.room:alivePlayerCount() > 2 then
			return "."
		end
	else
		return "."
	end
end
--[[
	技能：弃世（限定技）
	描述：出牌阶段，你可以弃置区域中的所有牌，将武将牌恢复至游戏开始时的状态，摸四张牌，然后失去技能“冷绝”并获得技能“飞影”和“帷幕”。
]]--
--QiShiCard:Play
local qishi_skill = {
	name = "hpQiShi",
	getTurnUseCard = function(self, inclusive)
		if self.player:getMark("@hpQiShiMark") > 0 then
			return sgs.Card_Parse("#hpQiShiCard:.:")
		end
	end,
}
table.insert(sgs.ai_skills, qishi_skill)
sgs.ai_skill_use_func["#hpQiShiCard"] = function(card, use, self)
	local process = sgs.gameProcess(self.room)
	if self.role == "lord" then
		if process == "loyalist" or process == "loyalish" or process == "neutral" then
			return
		end
	elseif self.role == "loyalist" then
		if process == "loyalist" or process == "loyalish" or process == "neutral" then
			return
		elseif process == "dilemma" and not self:isWeak() then
			return
		end
	elseif self.role == "renegade" then
		if not self:isWeak() then
			return
		end
	elseif self.role == "rebel" then
		if process == "rebel" or process == "rebelish" or process == "neutral" then
			return
		elseif process == "dilemma" and not self:isWeak() then
			return
		end
	end
	local value = 0
	--手牌区
	local handcards = self.player:getHandcards()
	local n_peach = 0
	for _,c in sgs.qlist(handcards) do
		local dummy_use = {
			isDummy = true,
		}
		if c:isKindOf("BasicCard") then
			self:useBasicCard(c, dummy_use)
		elseif c:isKindOf("TrickCard") then
			self:useTrickCard(c, dummy_use)
		elseif c:isKindOf("EquipCard") then
			self:useEquipCard(c, dummy_use)
		end
		if dummy_use.card then
			return 
		end
		if c:isKindOf("Peach") then
			n_peach = n_peach + 1
		end
	end
	if n_peach > 1 then
		return 
	elseif n_peach > 0 then
		for _,friend in ipairs(self.friends) do
			if self:isWeak(friend) then
				return 
			end
		end
	end
	value = value - handcards:length()
	--装备区
	local equips = self.player:getEquips()
	value = value - equips:length()
	--判定区
	local judges = self.player:getJudgingArea()
	if self.player:containsTrick("YanxiaoCard") then
		value = value - judges:length()
	end
	--翻回正面
	if not self.player:faceUp() then
		value = value + 2.5
	end
	--解锁
	if self.player:isChained() then
		value = value + 1
	end
	--摸四张牌
	value = value + 4
	--失去冷绝
	if self.player:hasSkill("hpLengJue") then
		value = value - 4
		for _,enemy in ipairs(self.enemies) do
			if self.player:inMyAttackRange(enemy) and self:isWeak(enemy) then
				value = value - 2
			end
		end
	end
	--获得飞影
	if not self.player:hasSkill("feiying") then
		value = value + 2
	end
	--获得帷幕
	if not self.player:hasSkill("weimu") then
		value = value + 5
	end
	if value > 0 then
		use.card = card
	end
end
--[[****************************************************************
	编号：HPIN - 009
	武将：王熙凤
	称号：雄情
	势力：吴
	性别：女
	体力上限：4勾玉
]]--****************************************************************
--[[
	技能：弄权
	描述：出牌阶段限一次，你可以选择两名角色，其中的每名角色均须交给你一张牌，否则受到另一名角色造成的1点伤害。若你以此法从其他角色处获得了两张牌，你摸一张牌并失去1点体力。
]]--
--room:askForCard(current, "..", prompt, data, sgs.Card_MethodNone, source, false, "hpNongQuan", true)
sgs.ai_skill_cardask["@hpNongQuan"] = function(self, data, pattern, target, target2, arg, arg2)
	local other = data:toPlayer()
	local isSourceFriend = self:isFriend(target)
	if isSourceFriend then
		if self.player:getArmor() and self:needToThrowArmor() then
			return "$"..self.player:getArmor():getEffectiveId()
		elseif self.player:hasEquip() and self:hasSkills(sgs.lose_equip_skill) then
			local equips = self.player:getEquips()
			equips = sgs.QList2Table(equips)
			self:sortByKeepValue(equips)
			return "$"..equips[1]:getEffectiveId()
		elseif self.player:objectName() == target:objectName() then
			local cards = self.player:getCards("he")
			return "$"..cards:first():getEffectiveId()
		end
	end
	if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, other) then
		return "."
	elseif self:needToLoseHp(self.player, other, false) then
		return "."
	elseif self:getCardsNum("Peach") > 0 and not self.player:hasFlag("Global_PreventPeach") then
		return "."
	end
	local isSourceEnemy = self:isEnemy(target)
	if self.player:getHandcardNum() == 1 then
		if isSourceEnemy and self:hasSkills("juece|nosjuece", target) and not self.player:hasEquip() then
			return "."
		elseif self:needKongcheng() then
			local handcards = self.player:getHandcards()
			return "$"..handcards:first():getEffectiveId()
		end
	end
	self.player:setFlags("Global_AIDiscardExchanging")
	local ids = self:askForDiscard("dummy", 1, 1, false, true)
	self.player:setFlags("-Global_AIDiscardExchanging")
	if #ids > 0 then
		return "$"..ids[1]
	end
	return "."
end
--NongQuanCard:Play
local nongquan_skill = {
	name = "hpNongQuan",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#hpNongQuanCard") then
			return nil
		end
		return sgs.Card_Parse("#hpNongQuanCard:.:")
	end,
}
table.insert(sgs.ai_skills, nongquan_skill)
sgs.ai_skill_use_func["#hpNongQuanCard"] = function(card, use, self)
	local targetA, targetB = nil, nil
	local alives = self.room:getAlivePlayers()
	local isFriend, isEnemy = {}, {}
	for _,p in sgs.qlist(alives) do
		if self:isFriend(p) then
			isFriend[p:objectName()] = true
			isEnemy[p:objectName()] = false
		elseif self:isEnemy(p) then
			isFriend[p:objectName()] = false
			isEnemy[p:objectName()] = true
		else
			isFriend[p:objectName()] = false
			isEnemy[p:objectName()] = false
		end
	end
	local JinXuanDi = self.room:findPlayerBySkillName("wuling")
	local fire_flag = ( JinXuanDi and JinXuanDi:getMark("@fire") > 0 )
	local function getDamageCount(source, victim)
		if source:hasSkill("jueqing") then
			return 1
		elseif self:damageIsEffective(victim, sgs.DamageStruct_Normal, source) then
			local damage = 1
			if victim:isKongcheng() and victim:hasSkill("chouhai") then
				damage = damage + 1
			end
			if fire_flag then
				if victim:hasArmorEffect("vine") or victim:hasArmorEffect("gale_shell") then
					damage = damage + 1
				end
			end
			if damage > 1 and victim:hasArmorEffect("silver_lion") then
				damage = 1
			end
			return damage
		end
		return 0
	end
	local my_hp = self.player:getHp()
	local my_peach = self:getAllPeachNum()
	local function getNongQuanValue(playerA, playerB)
		if playerA:objectName() == playerB:objectName() then
			return -1000
		end
		local value = 0
		local count = 0
		if playerA:isNude() then
			local damage = getDamageCount(playerB, playerA)
			if damage > 0 then
				local v = damage * 2
				if isFriend[playerA:objectName()] then
					v = 0 - v
				end
				if self:cantbeHurt(playerA, playerB, damage) then
					if isFriend[playerB:objectName()] then
						v = v - 30
					elseif isEnemy[playerB:objectName()] then
						v = v + 10
					end
				end
				if self:getDamagedEffects(playerA, playerB, false) then
					if isFriend[playerB:objectName()] then
						v = v - 2
					elseif isEnemy[playerB:objectName()] then
						v = v + 1.8
					end
				end
				value = value + v
			elseif isFriend[playerA:objectName()] then
				value = value + 0.1
			end
		else
			local notMe = ( playerA:objectName() ~= self.player:objectName() )
			if notMe then
				count = count + 1
			end
			local v = 0
			if playerA:getHandcardNum() == 1 and self:needKongcheng(playerA) then
				v = v - 0.2
			end
			if playerA:getArmor() and self:needToThrowArmor(playerA) then
				v = v - 2
			end
			if playerA:hasEquip() and self:hasSkills(sgs.lose_equip_skill, playerA) then
				v = v - 1.8
			end
			if playerA:hasSkill("tuntian") and playerA:getPhase() == sgs.Player_NotActive then
				v = v - 0.8
			end
			if isFriend[playerA:objectName()] then
				v = 0 - v*0.8
				if notMe then
					v = v - 0.1
				end
			elseif isEnemy[playerA:objectName()] then
				v = v + 2
			end
			value = value + v
		end
		if playerB:isNude() then
			local damage = getDamageCount(playerA, playerB)
			if damage > 0 then
				local v = damage * 2
				if isFriend[playerB:objectName()] then
					v = 0 - v
				end
				if self:cantbeHurt(playerB, playerA, damage) then
					if isFriend[playerA:objectName()] then
						v = v - 30
					elseif isEnemy[playerA:objectName()] then
						v = v + 10
					end
				end
				if self:getDamagedEffects(playerB, playerA, false) then
					if isFriend[playerA:objectName()] then
						v = v - 2
					elseif isEnemy[playerA:objectName()] then
						v = v + 1.8
					end
				end
				value = value + v
			elseif isFriend[playerB:objectName()] then
				value = value + 0.1
			end
		else
			local notMe = ( playerB:objectName() ~= self.player:objectName() )
			if notMe then
				count = count + 1
			end
			local v = 0
			if playerB:getHandcardNum() == 1 and self:needKongcheng(playerB) then
				v = v - 0.2
			end
			if playerB:getArmor() and self:needToThrowArmor(playerB) then
				v = v - 2
			end
			if playerB:hasEquip() and self:hasSkills(sgs.lose_equip_skill, playerB) then
				v = v - 1.8
			end
			if playerB:hasSkill("tuntian") and playerB:getPhase() == sgs.Player_NotActive then
				v = v - 0.8
			end
			if isFriend[playerB:objectName()] then
				v = 0 - v*0.8
				if notMe then
					v = v - 0.1
				end
			elseif isEnemy[playerB:objectName()] then
				v = v + 2
			end
			value = value + v
		end
		if count == 2 then
			value = value + 1 -- draw
			value = value - 2 -- lose hp
			if my_hp <= 1 then
				value = value - 1
				if self.player:hasSkill("hpSuanJin") then
					value = value - 10
					if self.player:getMaxHp() <= 1 then
						value = value - 100
					end
				end
				if my_peach == 0 then
					value = value - 50
				end
			end
		end
		return value
	end
	local maxValue = 0
	if self.player:getHp() > getBestHp(self.player) then
		maxValue = maxValue - 1
	elseif self:needToLoseHp() then
		maxValue = maxValue - 0.5
	end
	if self.player:getHp() > 1 and self:getCardsNum("Peach") > 0 then
		maxValue = maxValue - 0.5
	end
	if self:getOverflow() > 0 then
		maxValue = maxValue - 0.25
	end
	if self:isWeak() then
		maxValue = maxValue + 0.5
	end
	local visited = {}
	for _,playerA in sgs.qlist(alives) do
		local nameA = playerA:objectName()
		for _,playerB in sgs.qlist(alives) do
			local nameB = playerB:objectName()
			if not visited[nameB..nameA] then
				visited[nameA..nameB] = true
				local value = getNongQuanValue(playerA, playerB)
				if value > maxValue then
					maxValue = value
					targetA, targetB = playerA, playerB
				end
			end
		end
	end
	if targetA and targetB then
		use.card = card
		if use.to then
			use.to:append(targetA)
			use.to:append(targetB)
		end
	end
end
--相关信息
sgs.ai_use_value["hpNongQuanCard"] = 7
sgs.ai_use_priority["hpNongQuanCard"] = 5.1
--[[
	技能：算尽（锁定技）
	描述：你濒死时，失去1点体力上限。
]]--
--[[****************************************************************
	编号：HPIN - 010
	武将：贾巧姐
	称号：恩情
	势力：吴
	性别：女
	体力上限：3勾玉
]]--****************************************************************
--[[
	技能：乞巧（限定技）
	描述：准备阶段开始时，若你的手牌数不足7，你可以将手牌补至七张。
]]--
--player:askForSkillInvoke("hpQiQiao", data)
sgs.ai_skill_invoke["hpQiQiao"] = function(self, data)
	if self:willSkipPlayPhase() then
		return false
	elseif #self.enemies == 0 then
		return false
	elseif self.player:isKongcheng() then
		return true
	elseif self.player:getHandcardNum() <= 2 and self:isWeak() then
		return true
	end
	return false
end
--[[
	技能：交缘
	描述：出牌阶段限一次，你可以交给一名其他角色一张牌，然后获得其一张牌。若如此做，你回复1点体力。
]]--
--room:askForCardChosen(source, target, "he", "hpJiaoYuan")
--JiaoYuanCard:Play
local jiaoyuan_skill = {
	name = "hpJiaoYuan",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#hpJiaoYuanCard") then
			return nil
		elseif self.player:isNude() then
			return nil
		end
		return sgs.Card_Parse("#hpJiaoYuanCard:.:")
	end,
}
table.insert(sgs.ai_skills, jiaoyuan_skill)
sgs.ai_skill_use_func["#hpJiaoYuanCard"] = function(card, use, self)
	local target = nil
	for _,friend in ipairs(self.friends_noself) do
		if friend:hasEquip() and self:hasSkills(sgs.lose_equip_skill, friend) then
			if not hasManjuanEffect(friend) then
				target = friend
				break
			end
		end
	end
	if not target then
		for _,enemy in ipairs(self.enemies) do
			if self:getDangerousCard(enemy) then
				target = enemy
				break
			end
		end
	end
	if not target then
		for _,friend in ipairs(self.friends_noself) do
			if friend:getArmor() and self:needToThrowArmor(friend) then
				target = friend
				break
			end
		end
	end
	if not target then
		for _,enemy in ipairs(self.enemies) do
			if self:getValuableCard(enemy) then
				target = enemy
				break
			end
		end
	end
	if not target then
		self:sort(self.enemies, "handcard")
		for _,enemy in ipairs(self.enemies) do
			if not enemy:hasSkill("tuntian") then
				local handcards = enemy:getHandcards()
				local flag = string.format("visible_%s_%s", self.player:objectName(), enemy:objectName())
				for _,c in sgs.qlist(handcards) do
					if c:hasFlag("visible") or c:hasFlag(flag) then
						if c:isKindOf("Peach") or c:isKindOf("Analeptic") or c:isKindOf("ExNihilo") then
							target = enemy
							break
						end
					end
				end
				if target then
					break
				end
			end
		end
	end
	if not target then
		for _,friend in ipairs(self.friends_noself) do
			if hasManjuanEffect(friend) then
			elseif friend:hasSkill("tuntian") then
				target = friend
				break
			end
		end
	end
	if not target then
		for _,enemy in ipairs(self.enemies) do
			if hasManjuanEffect(enemy) then
				target = enemy
				break
			end
		end
	end
	if not target and self.player:getHp() < getBestHp(self.player) then
		local others = self.room:getOtherPlayers(self.player)
		for _,p in sgs.qlist(others) do
			if p:isNude() then
				target = p
				break
			end
		end
		if not target then
			for _,p in sgs.qlist(others) do
				if not p:inMyAttackRange(self.player) then
					target = p
					break
				end
			end
		end
		if not target then
			target = others:first()
		end
	end
	local to_use = nil
	if target then
		local may_use = self:askForDiscard("dummy", 1, 1, false, true)
		if #may_use == 1 then
			to_use = may_use[1]
		end
	end
	if target and to_use then
		local card_str = "#hpJiaoYuanCard:"..to_use..":"
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end
--相关信息
sgs.ai_use_value["hpJiaoYuanCard"] = 4.2
sgs.ai_use_priority["hpJiaoYuanCard"] = 5.1
--[[****************************************************************
	编号：HPIN - 011
	武将：李纨
	称号：槁情
	势力：蜀
	性别：女
	体力上限：3勾玉
]]--****************************************************************
--[[
	技能：稻香
	描述：你可以将一张基本牌当一张基本牌使用或打出。
]]--
--room:askForChoice(user, "hpDaoXiangChooseToUse", choices)
sgs.ai_skill_choice["hpDaoXiangChooseToUse"] = function(self, choices, data)
	local items = choices:split("+")
	local choice = sgs.ai_daoxiang_choice
	if choice then
		sgs.ai_daoxiang_choice = nil
		for _,item in ipairs(items) do
			if item == choice then
				return item
			end
		end
	end
	return items[math.random(1, #items)]
end
--room:askForChoice(user, "hpDaoXiangChooseToResponse", choices)
sgs.ai_skill_choice["hpDaoXiangChooseToResponse"] = function(self, choices, data)
	local items = choices:split("+")
	local choice = sgs.ai_daoxiang_choice
	if choice then
		sgs.ai_daoxiang_choice = nil
		for _,item in ipairs(items) do
			if item == choice then
				return item
			end
		end
	end
	return items[math.random(1, #items)]
end
--room:askForUseCard(user, "@@hpDaoXiang", prompt)
sgs.ai_skill_use["@@hpDaoXiang"] = function(self, prompt, method)
	local name = self.player:property("hpDaoXiangCardName"):toString()
	local suit = self.player:getMark("hpDaoXiangCardSuit")
	local point = self.player:getMark("hpDaoXiangCardNumber")
	local card = sgs.Sanguosha:cloneCard(name, suit, point)
	if card then
		card:deleteLater()
		local dummy_use = {
			isDummy = true,
			to = sgs.SPlayerList(),
		}
		self:useBasicCard(card, dummy_use)
		local targets = {}
		for _,target in sgs.qlist(dummy_use.to) do
			table.insert(targets, target:objectName())
		end
		if #targets == 0 then
			return "."
		end
		return "#hpDaoXiangSelectCard:.:->"..table.concat(targets, "+")
	end
	return "."
end
--DaoXiangCard:Play
local daoxiang_skill = {
	name = "hpDaoXiang",
	getTurnUseCard = function(self, inclusive)
		if self.player:isNude() then
			return nil
		elseif sgs.Slash_IsAvailable(self.player) then
			return sgs.Card_Parse("#hpDaoXiangCard:.:slash")
		elseif sgs.Analeptic_IsAvailable(self.player) then
			return sgs.Card_Parse("#hpDaoXiangCard:.:analeptic")
		elseif self.player:getLostHp() > 0 and not self.player:hasFlag("Global_PreventPeach") then
			return sgs.Card_Parse("#hpDaoXiangCard:.:peach")
		end
	end,
}
table.insert(sgs.ai_skills, daoxiang_skill)
sgs.ai_skill_use_func["#hpDaoXiangCard"] = function(card, use, self)
	local handcards = self.player:getHandcards()
	local basics = {}
	for _,c in sgs.qlist(handcards) do
		if c:isKindOf("BasicCard") then
			table.insert(basics, c)
		end
	end
	if #basics == 0 then
		return 
	end
	local needPeach, needAnaleptic, needSlash, needFireSlash, needThunderSlash = false, false, false, false, false
	local hasPeach, hasAnaleptic, hasSlash, hasFireSlash, hasThunderSlash = nil, nil, nil, nil, nil
	local to_use = nil
	for _,c in ipairs(basics) do
		if not hasPeach and c:isKindOf("Peach") then
			hasPeach = c
		elseif not hasAnaleptic and c:isKindOf("Analeptic") then
			hasAnaleptic = c
		elseif not hasFireSlash and c:isKindOf("FireSlash") then
			hasFireSlash = c
		elseif not hasThunderSlash and c:isKindOf("ThunderSlash") then
			hasThunderSlash = c
		elseif not hasSlash and c:isKindOf("Slash") and not c:isKindOf("NatureSlash") then
			hasSlash = c
		end
	end
	if not hasPeach and self.player:getLostHp() > 0 and not self.player:hasFlag("Global_PreventPeach") then
		local peach = sgs.Sanguosha:cloneCard("peach")
		peach:deleteLater()
		local dummy_use = {
			isDummy = true,
		}
		self:useBasicCard(peach, dummy_use)
		if dummy_use.card then
			needPeach = true
		end
	end
	if not needPeach and #basics == 1 and self:getOverflow() <= 0 then
		return 
	end
	if not needPeach and sgs.Slash_IsAvailable(self.player) then
		if not hasFireSlash then
			local fire_slash = sgs.Sanguosha:cloneCard("fire_slash")
			fire_slash:deleteLater()
			local dummy_use = {
				isDummy = true,
			}
			self:useBasicCard(fire_slash, dummy_use)
			if dummy_use.card then
				needFireSlash = true
			end
		end
		if not needFireSlash and not hasThunderSlash then
			local thunder_slash = sgs.Sanguosha:cloneCard("thunder_slash")
			thunder_slash:deleteLater()
			local dummy_use = {
				isDummy = true,
			}
			self:useBasicCard(thunder_slash, dummy_use)
			if dummy_use.card then
				needThunderSlash = true
			end
		end
		if not needFireSlash and not needThunderSlash and not hasSlash then
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:deleteLater()
			local dummy_use = {
				isDummy = true,
			}
			self:useBasicCard(slash, dummy_use)
			if dummy_use.card then
				needSlash = true
			end
		end
		if not hasAnaleptic and sgs.Analeptic_IsAvailable(self.player) then
			if hasSlash or hasFireSlash or hasThunderSlash then
				local analeptic = sgs.Sanguosha:cloneCard("analeptic")
				analeptic:deleteLater()
				local dummy_use = {
					isDummy = true,
				}
				self:useBasicCard(analeptic, dummy_use)
				if dummy_use.card then
					needAnaleptic = true
				end
			end
		end
	end
	if needPeach or needAnaleptic or needFireSlash or needThunderSlash or needSlash then
		self:sortByKeepValue(basics)
		local name = nil
		if needPeach and not hasPeach then
			to_use, name = basics[1], "peach"
			sgs.ai_daoxiang_choice = "peach"
		elseif needAnaleptic and not hasAnaleptic then
			to_use, name = basics[1], "analeptic"
			sgs.ai_daoxiang_choice = "analeptic"
		elseif needFireSlash and not hasFireSlash then
			to_use, name = basics[1], "fire_slash"
			sgs.ai_daoxiang_choice = "fire_slash" 
		elseif needThunderSlash and not hasThunderSlash then
			to_use, name = basics[1], "thunder_slash"
			sgs.ai_daoxiang_choice = "thunder_slash"
		elseif needSlash and not hasSlash then
			to_use, name = basics[1], "slash"
			sgs.ai_daoxiang_choice = "slash"
		end
		if to_use and name then
			local card_str = "#hpDaoXiangCard:"..to_use:getEffectiveId()..":"..name
			local acard = sgs.Card_Parse(card_str)
			assert(acard)
			use.card = acard
		end
	end
end
--DaoXiangCard:Response
sgs.ai_cardsview_valuable["hpDaoXiang"] = function(self, class_name, player)
	if player:hasFlag("AI_DaoXiang_StackOverflow") then
		return
	elseif player:isKongcheng() then
		return
	elseif class_name == "Slash" then
		local handcards = player:getHandcards()
		local basics = {}
		for _,c in sgs.qlist(handcards) do
			if c:isKindOf("BasicCard") and not c:isKindOf("Slash") then
				table.insert(basics, c)
			end
		end
		if #basics > 0 then
			player:setFlags("AI_DaoXiang_StackOverflow")
			self:sortByKeepValue(basics)
			player:setFlags("-AI_DaoXiang_StackOverflow")
			local card_str = "#hpDaoXiangCard:"..basics[1]:getEffectiveId()..":slash"
			return card_str
		end
	elseif class_name == "Jink" then
		local handcards = player:getHandcards()
		local basics = {}
		for _,c in sgs.qlist(handcards) do
			if c:isKindOf("BasicCard") and not c:isKindOf("Jink") then
				table.insert(basics, c)
			end
		end
		if #basics > 0 then
			player:setFlags("AI_DaoXiang_StackOverflow")
			self:sortByKeepValue(basics)
			player:setFlags("-AI_DaoXiang_StackOverflow")
			local card_str = "#hpDaoXiangCard:"..basics[1]:getEffectiveId()..":jink"
			return card_str
		end
	elseif class_name == "Peach" then
		local handcards = player:getHandcards()
		local basics = {}
		for _,c in sgs.qlist(handcards) do
			if c:isKindOf("BasicCard") and not c:isKindOf("Peach") then
				table.insert(basics, c)
			end
		end
		if #basics > 0 then
			player:setFlags("AI_DaoXiang_StackOverflow")
			self:sortByKeepValue(basics)
			player:setFlags("-AI_DaoXiang_StackOverflow")
			local card_str = "#hpDaoXiangCard:"..basics[1]:getEffectiveId()..":peach"
			return card_str
		end
	elseif class_name == "Analeptic" then
		local handcards = player:getHandcards()
		local basics = {}
		for _,c in sgs.qlist(handcards) do
			if c:isKindOf("BasicCard") and not c:isKindOf("Analeptic") then
				table.insert(basics, c)
			end
		end
		if #basics > 0 then
			player:setFlags("AI_DaoXiang_StackOverflow")
			self:sortByKeepValue(basics)
			player:setFlags("-AI_DaoXiang_StackOverflow")
			local card_str = "#hpDaoXiangCard:"..basics[1]:getEffectiveId()..":analeptic"
			return card_str
		end
	end
end
--相关信息
sgs.ai_use_value["hpDaoXiangCard"] = 3
sgs.ai_use_priority["hpDaoXiangCard"] = 6
--[[
	技能：心血
	描述：一名你攻击范围内的角色被指定为【杀】或【决斗】的唯一目标时，你可以令其摸一张牌，然后你代替其成为此【杀】或决斗的目标。若如此做，每当该角色杀死一名角色后，你摸X张牌（X为你的体力且至少为1）。
]]--
--p:askForSkillInvoke("hpXinXue", sgs.QVariant(prompt))
sgs.ai_skill_invoke["hpXinXue"] = function(self, data)
	local prompt = data:toString()
	local hints = prompt:split(":")
	local source_name, victim_name, card_name = hints[2], hints[3], hints[4]
	local alives = self.room:getAlivePlayers()
	local victim = nil
	for _,p in sgs.qlist(alives) do
		if p:objectName() == victim_name then
			victim = p
			break
		end
	end
	if victim and self:isFriend(victim) then
		local source = nil
		for _,p in sgs.qlist(alives) do
			if p:objectName() == source_name then
				source = p
				break
			end
		end
		local tag = self.room:getTag("hpXinXueData")
		local use = tag:toCardUse()
		local card = use.card
		local damage = 0
		local isSlash = card:isKindOf("Slash")
		local JinXuanDi = self.room:findPlayerBySkillName("wuling")
		local Fire = ( JinXuanDi and JinXuanDi:getMark("@fire") > 0 )
		local isDuel = card:isKindOf("Duel")
		local sourceSlashNum = 0
		if isSlash then
			if not self:slashIsEffective(card, victim, source) then
				return false
			elseif source then
				if self:canHit(victim, source) and not self:canHit(self.player, source) then
					return true
				end
			end
			damage = self:hasHeavySlashDamage(source, card, victim, true)
		elseif card:isKindOf("Duel") then
			if not self:hasTrickEffective(card, victim, source) then
				return false
			end
			if source:objectName() == self.player:objectName() then
				sourceSlashNum = self:getCardsNum("Slash")
			else
				sourceSlashNum = getCardsNum("Slash", source, self.player)
			end
			if getCardsNum("Slash", victim, self.player) > sourceSlashNum then
				return false
			end
			damage = 1
			if Fire then
				if victim:hasArmorEffect("vine") or victim:hasArmorEffect("gale_shell") then
					damage = damage + 1
				end
			end
			if victim:hasSkill("chouhai") and victim:isKongcheng() then
				damage = damage + 1
			end
			if damage > 1 and victim:hasArmorEffect("silver_lion") then
				damage = 1
			end
		end
		local myhp, hp = self.player:getHp(), victim:getHp()
		if hp > damage and self:getDamagedEffects(victim, source, isSlash) then
			return false
		end
		local mydamage = 0
		if isSlash then
			mydamage = self:hasHeavySlashDamage(source, card, self.player, true)
		elseif card:isKindOf("Duel") then
			if self:hasTrickEffective(card, self.player, source) then
				if self:getCardsNum("Slash") <= sourceSlashNum then
					mydamage = 1
					if Fire then
						if self.player:hasArmorEffect("vine") or self.player:hasArmorEffect("gale_shell") then
							mydamage = mydamage + 1
						end
					end
					if self.player:hasSkill("chouhai") and self.player:isKongcheng() then
						mydamage = mydamage + 1
					end
					if mydamage > 1 and self.player:hasArmorEffect("silver_lion") then
						mydamage = 1
					end
				end
			end
		end
		return myhp > mydamage
	end
	return false
end
--[[****************************************************************
	编号：HPIN - 012
	武将：秦可卿
	称号：孽情
	势力：群
	性别：女
	体力上限：4勾玉
]]--****************************************************************
--[[
	技能：迷津
	描述：出牌阶段限一次，你可以令你攻击范围内的一名角色选择一项：交给你一张红心手牌，或者失去1点体力。
]]--
--room:askForCard(target, ".|heart|.|hand", prompt, data, sgs.Card_MethodNone, source, false, "hpMiJin")
sgs.ai_skill_cardask["@hpMiJin"] = function(self, data, pattern, target, target2, arg, arg2)
	if self:needToLoseHp(self.player, target, false) then
		return "."
	end
	local handcards = self.player:getHandcards()
	local hearts = {}
	local isEnemy = self:isEnemy(target)
	for _,c in sgs.qlist(handcards) do
		if isEnemy and isCard("Peach", c, self.player) then
			return "."
		elseif c:getSuit() == sgs.Card_Heart then
			table.insert(hearts, c)
		end
	end
	if #hearts == 0 then
		return "."
	end
	self:sortByKeepValue(hearts)
	return "$"..hearts[1]:getEffectiveId()
end
--MiJinCard:Play
local mijin_skill = {
	name = "hpMiJin",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#hpMiJinCard") then
			return nil
		elseif #self.enemies == 0 then
			return nil
		end
		return sgs.Card_Parse("#hpMiJinCard:.:")
	end,
}
table.insert(sgs.ai_skills, mijin_skill)
sgs.ai_skill_use_func["#hpMiJinCard"] = function(card, use, self)
	self:sort(self.enemies, "defense")
	local target = nil
	for _,enemy in ipairs(self.enemies) do
		if enemy:hasSkill("zhaxiang") or enemy:hasSkill("tuntian") then
		else
			target = enemy
			break
		end
	end
	target = target or self.enemies[1]
	use.card = card
	if use.to then
		use.to:append(target)
	end
end
--相关信息
sgs.ai_use_value["hpMiJinCard"] = 3.5
sgs.ai_use_priority["hpMiJinCard"] = 8.1
sgs.ai_card_intention["hpMiJinCard"] = function(self, card, from, tos)
	for _,to in ipairs(tos) do
		if self:needToLoseHp(to, from, false, true) then
		elseif self:hasSkills("zhaxiang|tuntian", to) then
		else
			sgs.updateIntention(from, to, 80)
		end
	end
end
--[[
	技能：托梦
	描述：你死亡时，你可以令一名角色观看牌堆顶的五张牌并将之以任意次序置于牌堆顶，然后该角色进行一次判定。若结果为【闪】，其与其攻击范围内的所有角色依次回复1点体力；若不为【闪】，其与其攻击范围内的所有角色依次失去1点体力上限。
]]--
--room:askForPlayerChosen(player, alives, "hpTuoMeng", "@hpTuoMeng", true, true)
sgs.ai_skill_playerchosen["hpTuoMeng"] = function(self, targets)
	local function getTuoMengValue(target)
		local value = 0
		local alives = self.room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if target:objectName() == p:objectName() or target:inMyAttackRange(p) then
				if self:isFriend(p) then
					value = value - 10
					if p:getMaxHp() <= 1 then
						value = value - 50
					end
				else
					value = value + 10
					if p:getMaxHp() <= 1 then
						value = value + 50
					end
				end
			end
		end
		return value
	end
	local maxValue, maxTarget = -999, nil
	for _,target in sgs.qlist(targets) do
		local value = getTuoMengValue(target)
		if value > maxValue then
			maxValue = value
			maxTarget = target
		end
	end
	return maxTarget
end
--room:askForGuanxing(target, card_ids, sgs.Room_GuanxingUpOnly)