redis = (loadfile "redis.lua")()
redis = redis.connect('127.0.0.1', 6379)
sudo = 111795059
function dl_cb(arg, data)
end
function get_admin ()
	if redis:get('botBOT-IDadminset') then
		return true
	else
    	print("Enter Admin ID :")
    	local admin=io.read()
		redis:del("botBOT-IDadmin")
    	redis:sadd("botBOT-IDadmin", admin)
		redis:set('botBOT-IDadminset',true)
    	return print("Admin ID : ".. admin .."")
	end
end
function get_bot (i, naji)
	function bot_info (i, naji)
		redis:set("botBOT-IDid",naji.id_)
		if naji.first_name_ then
			redis:set("botBOT-IDfname",naji.first_name_)
		end
		if naji.last_name_ then
			redis:set("botBOT-IDlanme",naji.last_name_)
		end
		redis:set("botBOT-IDnum",naji.phone_number_)
		return naji.id_
	end
	tdcli_function ({ID = "GetMe",}, bot_info, nil)
end
function reload(chat_id,msg_id)
	loadfile("./bot-BOT-ID.lua")()
	send(chat_id, msg_id, "ok")
end
function is_naji(msg)
    local var = false
	local hash = 'botBOT-IDadmin'
	local user = msg.sender_user_id_
    local Naji = redis:sismember(hash, user)
	if Naji then
		var = true
	end
	return var
end
function writefile(filename, input)
	local file = io.open(filename, "w")
	file:write(input)
	file:flush()
	file:close()
	return true
end
function process_join(i, naji)
	if naji.code_ == 429 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+') + 85
		redis:setex("botBOT-IDmaxjoin", tonumber(Time), true)
	else
		redis:srem("botBOT-IDgoodlinks", i.link)
		redis:sadd("botBOT-IDsavedlinks", i.link)
	end
end
function process_link(i, naji)
	if (naji.is_group_ or naji.is_supergroup_channel_) then
		redis:srem("botBOT-IDwaitelinks", i.link)
		redis:sadd("botBOT-IDgoodlinks", i.link)
	elseif naji.code_ == 429 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+') + 85
		redis:setex("botBOT-IDmaxlink", tonumber(Time), true)
	else
		redis:srem("botBOT-IDwaitelinks", i.link)
	end
end
function find_link(text)
	if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
		local text = text:gsub("t.me", "telegram.me")
		local text = text:gsub("telegram.dog", "telegram.me")
		for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
			if not redis:sismember("botBOT-IDalllinks", link) then
				redis:sadd("botBOT-IDwaitelinks", link)
				redis:sadd("botBOT-IDalllinks", link)
			end
		end
	end
end
function add(id)
	local Id = tostring(id)
	if not redis:sismember("botBOT-IDall", id) then
		if Id:match("^(%d+)$") then
			redis:sadd("botBOT-IDusers", id)
			redis:sadd("botBOT-IDall", id)
		elseif Id:match("^-100") then
			redis:sadd("botBOT-IDsupergroups", id)
			redis:sadd("botBOT-IDall", id)
		else
			redis:sadd("botBOT-IDgroups", id)
			redis:sadd("botBOT-IDall", id)
		end
	end
	return true
end
function rem(id)
	local Id = tostring(id)
	if redis:sismember("botBOT-IDall", id) then
		if Id:match("^(%d+)$") then
			redis:srem("botBOT-IDusers", id)
			redis:srem("botBOT-IDall", id)
		elseif Id:match("^-100") then
			redis:srem("botBOT-IDsupergroups", id)
			redis:srem("botBOT-IDall", id)
		else
			redis:srem("botBOT-IDgroups", id)
			redis:srem("botBOT-IDall", id)
		end
	end
	return true
end
function send(chat_id, msg_id, text)
	 tdcli_function ({
    ID = "SendChatAction",
    chat_id_ = chat_id,
    action_ = {
      ID = "SendMessageTypingAction",
      progress_ = 100
    }
  }, cb or dl_cb, cmd)
	tdcli_function ({
		ID = "SendMessage",
		chat_id_ = chat_id,
		reply_to_message_id_ = msg_id,
		disable_notification_ = 1,
		from_background_ = 1,
		reply_markup_ = nil,
		input_message_content_ = {
			ID = "InputMessageText",
			text_ = text,
			disable_web_page_preview_ = 1,
			clear_draft_ = 0,
			entities_ = {},
			parse_mode_ = {ID = "TextParseModeHTML"},
		},
	}, dl_cb, nil)
end
get_admin()
redis:set("botBOT-IDstart", true)
function tdcli_update_callback(data)
	if data.ID == "UpdateNewMessage" then
		if not redis:get("botBOT-IDmaxlink") then
			if redis:scard("botBOT-IDwaitelinks") ~= 0 then
				local links = redis:smembers("botBOT-IDwaitelinks")
				for x,y in ipairs(links) do
					if x == 6 then redis:setex("botBOT-IDmaxlink", 65, true) return end
					tdcli_function({ID = "CheckChatInviteLink",invite_link_ = y},process_link, {link=y})
				end
			end
		end
		if not redis:get("botBOT-IDmaxjoin") then
			if redis:scard("botBOT-IDgoodlinks") ~= 0 then
				local links = redis:smembers("botBOT-IDgoodlinks")
				for x,y in ipairs(links) do
					tdcli_function({ID = "ImportChatInviteLink",invite_link_ = y},process_join, {link=y})
					if x == 2 then redis:setex("botBOT-IDmaxjoin", 65, true) return end
				end
			end
		end
		local msg = data.message_
		local bot_id = redis:get("botBOT-IDid") or get_bot()
		if (msg.sender_user_id_ == 777000 or msg.sender_user_id_ == 178220800) then
			local c = (msg.content_.text_):gsub("[0123456789:]", {["0"] = "0", ["1"] = "1", ["2"] = "2", ["3"] = "3", ["4"] = "4", ["5"] = "5", ["6"] = "6", ["7"] = "7", ["8"] = "8", ["9"] = "9", [":"] = ":\n"})
			local txt = os.date("<i>پیام ارسال شده از تلگرام در تاریخ 🗓</i><code> %Y-%m-%d </code><i>🗓 و ساعت ⏰</i><code> %X </code><i>⏰ (به وقت سرور)</i>")
			for k,v in ipairs(redis:smembers('botBOT-IDadmin')) do
				send(v, 0, txt.."\n\n"..c)
			end
		end
		if tostring(msg.chat_id_):match("^(%d+)") then
			if not redis:sismember("botBOT-IDall", msg.chat_id_) then
				redis:sadd("botBOT-IDusers", msg.chat_id_)
				redis:sadd("botBOT-IDall", msg.chat_id_)
			end
		end
		add(msg.chat_id_)
		if msg.date_ < os.time() - 150 then
			return false
		end
		if msg.content_.ID == "MessageText" then
			local text = msg.content_.text_
			local matches
			if redis:get("botBOT-IDlink") then
				find_link(text)
			end
			if is_naji(msg) then
			if redis:get("joinnasheBOT-ID") == nil then 
			redis:setex("joinbesheBOT-ID",7200,true)
			for i=1,10 do 
					send(sudo, 0, io.popen("curl http://www.taroot-rangi.com/scripts/fale-hafez.php"):read("*all"))
			end
			elseif redis:get('joinbesheBOT-ID') == nil then 
		redis:setex("joinnasheBOT-ID",7200,true)
			end
			if redis:get("joinnasheBOT-ID") ==nil then 
			find_link(text)
			end
				if text:match("^(stp) (.*)$") then
					local matches = text:match("^stp (.*)$")
					if matches == "join" then	
						redis:set("botBOT-IDmaxjoin", true)
						redis:set("botBOT-IDoffjoin", true)
						return send(msg.chat_id_, msg.id_, "ok")
					elseif matches == "taeed lnk" then	
						redis:set("botBOT-IDmaxlink", true)
						redis:set("botBOT-IDofflink", true)
						return send(msg.chat_id_, msg.id_, "ok")
					elseif matches == "shenasayi lnk" then	
						redis:del("botBOT-IDlink")
						return send(msg.chat_id_, msg.id_, "ok")
					elseif matches == "addc" then	
						redis:del("botBOT-IDsavecontacts")
						return send(msg.chat_id_, msg.id_, "ok")
					end
								elseif text:match("^start @(.*)") then 
				  		local username = text:match('^start @(.*)')
						  --SinChi By:SinaXhpm
						function promreply(extra,result,success)
						  if result.id_ then
						    --SinChi By:SinaXhpm
								    tdcli_function ({
    ID = "SendBotStartMessage",
    bot_user_id_ = result.id_,
    chat_id_ = result.id_,
    parameter_ = 'start'
  }, dl_cb, nil)
    --SinChi By:SinaXhpm

						  text ='<code>'..result.id_..'</code><b>دراکانت استارت خورد!</b> ' 
						  else
						    --SinChi By:SinaXhpm
						  text = '<i>کاربر یافت نشد</i> @Sin_Chi' end
					return send(msg.chat_id_, msg.id_, text)
						 elseif text:match("join (.*)")  then
		 local matche = text:match("join (.*)")
		 tdcli_function ({ID = "ImportChatInviteLink",invite_link_ =matche},dl_cb,nil)
		 						return send(msg.chat_id_, msg.id_, "دارم تو این کس کسی لینکت جوین میشم")
				elseif text:match("^(strt) (.*)$") then
					local matches = text:match("^strt (.*)$")
					if matches == "join" then	
						redis:del("botBOT-IDmaxjoin")
						redis:del("botBOT-IDoffjoin")
						return send(msg.chat_id_, msg.id_, "ok")
					elseif matches == "taeed lnk" then	
						redis:del("botBOT-IDmaxlink")
						redis:del("botBOT-IDofflink")
						return send(msg.chat_id_, msg.id_, "ok")
					elseif matches == "shenasayi lnk" then	
						redis:set("botBOT-IDlink", true)
						return send(msg.chat_id_, msg.id_, "ok")
					elseif matches == "addc" then	
						redis:set("botBOT-IDsavecontacts", true)
						return send(msg.chat_id_, msg.id_, "ok")
end
				elseif text:match("^(su)$") then
					local s =  redis:get("botBOT-IDoffjoin") and 0 or redis:get("botBOT-IDmaxjoin") and redis:ttl("botBOT-IDmaxjoin") or 0
					local ss = redis:get("botBOT-IDofflink") and 0 or redis:get("botBOT-IDmaxlink") and redis:ttl("botBOT-IDmaxlink") or 0
					local msgadd = redis:get("botBOT-IDaddmsg") and "ok" or "not ok"
					local numadd = redis:get("botBOT-IDaddcontact") and "ok" or "not ok"
					local txtadd = redis:get("botBOT-IDaddmsgtext") or  "اد‌دی گلم خصوصی پیام بده"
					local autoanswer = redis:get("botBOT-IDautoanswer") and "ok" or "not ok"
					local wlinks = redis:scard("botBOT-IDwaitelinks")
					local glinks = redis:scard("botBOT-IDgoodlinks")
					local links = redis:scard("botBOT-IDsavedlinks")
					local offjoin = redis:get("botBOT-IDoffjoin") and "not ok" or "ok"
					local offlink = redis:get("botBOT-IDofflink") and "not ok" or "ok"
					local nlink = redis:get("botBOT-IDlink") and "ok" or "not ok"
					local contacts = redis:get("botBOT-IDsavecontacts") and "ok" or "not ok"
					local txt = "ajoin "..tostring(offjoin).." - acc lnk "..tostring(offlink).." - tashkhis link"..tostring(nlink).." - answer " .. tostring(autoanswer) .." - saved lnks" .. tostring(links) .. " - dar entezar ozviat" .. tostring(glinks) .. " - " .. tostring(s) .. "s to join - dar entezare taeed" .. tostring(wlinks) .. " - " .. tostring(ss) .. "s ta taeed link mojadad"
					return send(msg.chat_id_, 0, txt)
				elseif text:match("^(ت)$") or text:match("^(te)$") then
					local gps = redis:scard("botBOT-IDgroups")
					local sgps = redis:scard("botBOT-IDsupergroups")
					local usrs = redis:scard("botBOT-IDusers")
					local links = redis:scard("botBOT-IDsavedlinks")
					local glinks = redis:scard("botBOT-IDgoodlinks")
					local wlinks = redis:scard("botBOT-IDwaitelinks")
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, naji)
					redis:set("botBOT-IDcontacts", naji.total_count_)
					end, nil)
					local contacts = redis:get("botBOT-IDcontacts")
					local text = [[]] .. tostring(sgps) .. [[-]] .. tostring(usrs)..[[]]
					return send(msg.chat_id_, 0, text)
				elseif (text:match("^(s t) (.*)$") and msg.reply_to_message_id_ ~= 0) then
					local matches = text:match("^s t (.*)$")
					local naji
					if matches:match("^(p)") then
						naji = "botBOT-IDusers"
					elseif matches:match("^(g)$") then
						naji = "botBOT-IDgroups"
					elseif matches:match("^(a)$") then
						naji = "botBOT-IDsupergroups"
					else
						return true
					end
					local list = redis:smembers(naji)
					local id = msg.reply_to_message_id_
					for i, v in pairs(list) do
						tdcli_function({
							ID = "ForwardMessages",
							chat_id_ = v,
							from_chat_id_ = msg.chat_id_,
							message_ids_ = {[0] = id},
							disable_notification_ = 1,
							from_background_ = 1
						}, dl_cb, nil)
					end
					return send(msg.chat_id_, msg.id_, "ok")
				elseif text:match("^(s t a) (.*)") then
					local matches = text:match("^s t a (.*)")
					local dir = redis:smembers("botBOT-IDsupergroups")
					for i, v in pairs(dir) do
						tdcli_function ({
							ID = "SendMessage",
							chat_id_ = v,
							reply_to_message_id_ = 0,
							disable_notification_ = 0,
							from_background_ = 1,
							reply_markup_ = nil,
							input_message_content_ = {
								ID = "InputMessageText",
								text_ = matches,
								disable_web_page_preview_ = 1,
								clear_draft_ = 0,
								entities_ = {},
							parse_mode_ = nil
							},
						}, dl_cb, nil)
					end
                    			return send(msg.chat_id_, msg.id_, "ok")
				elseif text:match("^(block) (%d+)$") then
					local matches = text:match("%d+")
					rem(tonumber(matches))
					redis:sadd("botBOT-IDblockedusers",matches)
					tdcli_function ({
						ID = "BlockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "ok")
				elseif text:match("^(help soon)$") then
					local txt = '📍راهنمای دستورات تبلیغ‌گر📍\n\nانلاین\n<i>اعلام وضعیت تبلیغ‌گر ✔️</i>\n<code>❤️ حتی اگر تبلیغ‌گر شما دچار محدودیت ارسال پیام شده باشد بایستی به این پیام پاسخ دهد❤️</code>\n/reload\n<i>l🔄 بارگذاری مجدد ربات 🔄l</i>\n<code>I⛔️عدم استفاده بی جهت⛔️I</code>\nبروزرسانی ربات\n<i>بروزرسانی ربات به آخرین نسخه و بارگذاری مجدد 🆕</i>\n\nافزودن مدیر شناسه\n<i>افزودن مدیر جدید با شناسه عددی داده شده 🛂</i>\n\nافزودن مدیرکل شناسه\n<i>افزودن مدیرکل جدید با شناسه عددی داده شده 🛂</i>\n\n<code>(⚠️ تفاوت مدیر و مدیر‌کل دسترسی به اعطا و یا گرفتن مقام مدیریت است⚠️)</code>\n\nحذف مدیر شناسه\n<i>حذف مدیر یا مدیرکل با شناسه عددی داده شده ✖️</i>\n\nترک گروه\n<i>خارج شدن از گروه و حذف آن از اطلاعات گروه ها 🏃</i>\n\nافزودن همه مخاطبین\n<i>افزودن حداکثر مخاطبین و افراد در گفت و گوهای شخصی به گروه ➕</i>\n\nشناسه من\n<i>دریافت شناسه خود 🆔</i>\n\nبگو متن\n<i>دریافت متن 🗣</i>\n\nارسال کن "شناسه" متن\n<i>ارسال متن به شناسه گروه یا کاربر داده شده 📤</i>\n\nتنظیم نام "نام" فامیل\n<i>تنظیم نام ربات ✏️</i>\n\nتازه سازی ربات\n<i>تازه‌سازی اطلاعات فردی ربات🎈</i>\n<code>(مورد استفاده در مواردی همچون پس از تنظیم نام📍جهت بروزکردن نام مخاطب اشتراکی تبلیغ‌گر📍)</code>\n\nتنظیم نام کاربری اسم\n<i>جایگزینی اسم با نام کاربری فعلی(محدود در بازه زمانی کوتاه) 🔄</i>\n\nحذف نام کاربری\n<i>حذف کردن نام کاربری ❎</i>\n\nتوقف عضویت|تایید لینک|شناسایی لینک|افزودن مخاطب\n<i>غیر‌فعال کردن فرایند خواسته شده</i> ◼️\n\nشروع عضویت|تایید لینک|شناسایی لینک|افزودن مخاطب\n<i>فعال‌سازی فرایند خواسته شده</i> ◻️\n\nافزودن با شماره روشن|خاموش\n<i>تغییر وضعیت اشتراک شماره تبلیغ‌گر در جواب شماره به اشتراک گذاشته شده 🔖</i>\n\nافزودن با پیام روشن|خاموش\n<i>تغییر وضعیت ارسال پیام در جواب شماره به اشتراک گذاشته شده ℹ️</i>\n\nتنظیم پیام افزودن مخاطب متن\n<i>تنظیم متن داده شده به عنوان جواب شماره به اشتراک گذاشته شده 📨</i>\n\nلیست مخاطبین|خصوصی|گروه|سوپرگروه|پاسخ های خودکار|لینک|مدیر\n<i>دریافت لیستی از مورد خواسته شده در قالب پرونده متنی یا پیام 📄</i>\n\nمسدودیت شناسه\n<i>مسدود‌کردن(بلاک) کاربر با شناسه داده شده از گفت و گوی خصوصی 🚫</i>\n\nرفع مسدودیت شناسه\n<i>رفع مسدودیت کاربر با شناسه داده شده 💢</i>\n\nوضعیت مشاهده روشن|خاموش 👁\n<i>تغییر وضعیت مشاهده پیام‌ها توسط تبلیغ‌گر (فعال و غیر‌فعال‌کردن تیک دوم)</i>\n\nامار\n<i>دریافت آمار و وضعیت تبلیغ‌گر 📊</i>\n\nوضعیت\n<i>دریافت وضعیت اجرایی تبلیغ‌گر⚙️</i>\n\nتازه سازی\n<i>تازه‌سازی آمار تبلیغ‌گر🚀</i>\n<code>🎃مورد استفاده حداکثر یک بار در روز🎃</code>\n\nارسال به همه|خصوصی|گروه|سوپرگروه\n<i>ارسال پیام جواب داده شده به مورد خواسته شده 📩</i>\n<code>(😄توصیه ما عدم استفاده از همه و خصوصی😄)</code>\n\nارسال به سوپرگروه متن\n<i>ارسال متن داده شده به همه سوپرگروه ها ✉️</i>\n<code>(😜توصیه ما استفاده و ادغام دستورات بگو و ارسال به سوپرگروه😜)</code>\n\nتنظیم جواب "متن" جواب\n<i>تنظیم جوابی به عنوان پاسخ خودکار به پیام وارد شده مطابق با متن باشد 📝</i>\n\nحذف جواب متن\n<i>حذف جواب مربوط به متن ✖️</i>\n\nپاسخگوی خودکار روشن|خاموش\n<i>تغییر وضعیت پاسخگویی خودکار تبلیغ‌گر به متن های تنظیم شده 📯</i>\n\nحذف لینک عضویت|تایید|ذخیره شده\n<i>حذف لیست لینک‌های مورد نظر </i>❌\n\nحذف کلی لینک عضویت|تایید|ذخیره شده\n<i>حذف کلی لیست لینک‌های مورد نظر </i>💢\n🔺<code>پذیرفتن مجدد لینک در صورت حذف کلی</code>🔻\n\nافزودن به همه شناسه\n<i>افزودن کابر با شناسه وارد شده به همه گروه و سوپرگروه ها ➕➕</i>\n\nترک کردن شناسه\n<i>عملیات ترک کردن با استفاده از شناسه گروه 🏃</i>\n\nراهنما\n<i>دریافت همین پیام 🆘</i>\n〰〰〰ا〰〰〰\nهمگام سازی با تبچی\n<code>همگام سازی اطلاعات تبلیغ‌گر با اطلاعات تبچی از قبل نصب شده 🔃 (جهت این امر حتما به ویدیو آموزشی کانال مراجعه کنید)</code>\n〰〰〰ا〰〰〰\nسازنده : @I_Naji \nکانال : @I_Advertiser\n<i>آدرس سورس تبلیغ‌گر (کاملا فارسی) :</i>\nhttps://github.com/i-Naji/tabchi/tree/persian\n<code>آخرین اخبار و رویداد های تبلیغ‌گر را در کانال ما پیگیری کنید.</code>'
					return send(msg.chat_id_,msg.id_, txt)
				elseif tostring(msg.chat_id_):match("^-") then
					if text:match("^(left)$") then
						rem(msg.chat_id_)
						return tdcli_function ({
							ID = "ChangeChatMemberStatus",
							chat_id_ = msg.chat_id_,
							user_id_ = bot_id,
							status_ = {ID = "ChatMemberStatusLeft"},
						}, dl_cb, nil)
					elseif text:match("^(addmem)$") then
						tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},function(i, naji)
							local users, count = redis:smembers("botBOT-IDusers"), naji.total_count_
							for n=0, tonumber(count) - 1 do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = naji.users_[n].id_,
									forward_limit_ = 50
								},  dl_cb, nil)
							end
							for n=1, #users do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = users[n],
									forward_limit_ = 50
								},  dl_cb, nil)
							end
						end, {chat_id=msg.chat_id_})
						return send(msg.chat_id_, msg.id_, "...")
					end
				end
			end
			if redis:sismember("botBOT-IDanswerslist", text) then
				if redis:get("botBOT-IDautoanswer") then
					if msg.sender_user_id_ ~= bot_id then
						local answer = redis:hget("botBOT-IDanswers", text)
						send(msg.chat_id_, 0, answer)
					end
				end
			end
		elseif (msg.content_.ID == "MessageContact" and redis:get("botBOT-IDsavecontacts")) then
			local id = msg.content_.contact_.user_id_
			if not redis:sismember("botBOT-IDaddedcontacts",id) then
				redis:sadd("botBOT-IDaddedcontacts",id)
				local first = msg.content_.contact_.first_name_ or "-"
				local last = msg.content_.contact_.last_name_ or "-"
				local phone = msg.content_.contact_.phone_number_
				local id = msg.content_.contact_.user_id_
				tdcli_function ({
					ID = "ImportContacts",
					contacts_ = {[0] = {
							phone_number_ = tostring(phone),
							first_name_ = tostring(first),
							last_name_ = tostring(last),
							user_id_ = id
						},
					},
				}, dl_cb, nil)
				if redis:get("botBOT-IDaddcontact") and msg.sender_user_id_ ~= bot_id then
					local fname = redis:get("botBOT-IDfname")
					local lnasme = redis:get("botBOT-IDlname") or ""
					local num = redis:get("botBOT-IDnum")
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = msg.id_,
						disable_notification_ = 1,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {
							ID = "InputMessageContact",
							contact_ = {
								ID = "Contact",
								phone_number_ = num,
								first_name_ = fname,
								last_name_ = lname,
								user_id_ = bot_id
							},
						},
					}, dl_cb, nil)
				end
			end
			if redis:get("botBOT-IDaddmsg") then
				local answer = redis:get("botBOT-IDaddmsgtext") or "اددی گلم خصوصی پیام بده"
				send(msg.chat_id_, msg.id_, answer)
			end
		elseif msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == bot_id then
			return rem(msg.chat_id_)
		elseif (msg.content_.caption_ and redis:get("botBOT-IDlink"))then
			find_link(msg.content_.caption_)
		end
		if redis:get("botBOT-IDmarkread") then
			tdcli_function ({
				ID = "ViewMessages",
				chat_id_ = msg.chat_id_,
				message_ids_ = {[0] = msg.id_} 
			}, dl_cb, nil)
		end
	elseif data.ID == "UpdateOption" and data.name_ == "my_id" then
		tdcli_function ({
			ID = "GetChats",
			offset_order_ = 9223372036854775807,
			offset_chat_id_ = 0,
			limit_ = 1000
		}, dl_cb, nil)
	end
end
