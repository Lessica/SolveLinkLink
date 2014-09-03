--一、源码声明
	--本脚本算法由 i_82 （Wu Zheng） 编写，版权所有，仿冒必究。

--二、脚本使用说明（要求越狱）
	--1、添加 Cydia 源：http://apt.touchsprite.com，安装触动精灵后注销。
	--2、将本脚本放置到 /User/Media/TouchSprite/lua 目录下，打开触动精灵并选择本脚本。
	--3、进入天天星连萌，单击开始游戏，然后按音量键启动，运行过程中可以随时按音量键结束运行。

----------------------------------------------
--以下内容不了解请勿修改，否则脚本很可能无法正常运行。
----------------------------------------------

--载入配置信息
function ts_lian_load_set()
	--载入环境变量
	SCREEN_WIDTH, SCREEN_HEIGHT = getScreenSize();
	SCREEN_RESOLUTION = "" .. SCREEN_WIDTH .. "x" .. SCREEN_HEIGHT .. "";
	SCREEN_COLOR_BITS = 8;
	DEVICE_TYPE, DEVICE_ID, TS_VER, OS_VER = getDeviceType(), getDeviceID(), getTSVer(), getOSVer();
	--加载游戏信息
	APP_IDENTIFIER, APP_ROTATION = "com.tencent.lian", 0;
	--延迟常量配置
	GREETINGS_DELAY, STARTING_DELAY, CHK_FRONT_APP_DELAY, ROUND_DELAY, CLICK_DELAY = 2, 2, 5, 100, 50;
	--按设备设定预先配置的信息
	if SCREEN_WIDTH == 640 and SCREEN_HEIGHT == 960 and DEVICE_TYPE == 1 then
		--iPod Touch 4 是不被支持的，而 iPhone 4 和 4S 是被支持的。
		p_origin_x, p_origin_y = 57, 130;
		p_width, p_height = 75, 100;
		p_counts_x, p_counts_y = 7, 7;
		p_precision, p_sampling = 3, 10;
		p_chkpos_a, p_chkpos_b, p_vaildnums = 8, 8, 6;
	elseif SCREEN_WIDTH == 640 and SCREEN_HEIGHT == 1136 and DEVICE_TYPE ~= 2 then
		--iPhone 5, 5S 和 iPod Touch 5 是被支持的。
		p_origin_x, p_origin_y = 57, 218;
		p_width, p_height = 75, 100;
		p_counts_x, p_counts_y = 7, 7;
		p_precision, p_sampling = 3, 10;
		p_chkpos_a, p_chkpos_b, p_vaildnums = 8, 8, 6;
	elseif SCREEN_WIDTH == 768 and SCREEN_HEIGHT == 1024 and DEVICE_TYPE == 2 then
		--iPad 1,2 和 iPad mini 1 是被支持的。
		return false;
	elseif SCREEN_WIDTH == 1536 and SCREEN_HEIGHT == 2048 and DEVICE_TYPE == 2 then
		--iPad 3,4,5 和 iPad mini 2 是被支持的。
		return false;
	else
		return false;
	end
	init(APP_IDENTIFIER, APP_ROTATION);
	return true;
end

--初始化坐标信息
function ts_lian_makepos()
	local i,j = 0, 0;
	pos = {};
	for i = 1, p_counts_x + 2, 1 do
		pos[i] = {};
		for j = 1, p_counts_y + 2, 1 do
			if i == 1 or j == 1 or i == p_counts_x + 2 or j == p_counts_y + 2 then
				pos[i][j] = {};
				pos[i][j][1], pos[i][j][2], pos[i][j][3] = -1, -1, -1;
			else
				pos[i][j] = {};
				pos[i][j][1], pos[i][j][2], pos[i][j][3] = p_origin_x + p_width * (i - 2), p_origin_y + p_height * (j - 2), -1;
			end
		end
	end
	ts_lian_rand();
end

--初始化随机采样点
function ts_lian_rand()
	rand = {};
	math.randomseed(os.time());
	local i = 0;
	for i = 1, p_sampling, 1 do
		rand[i] = {};
		rand[i][1] = math.random(20, p_width - 10);
		rand[i][2] = math.random(20, p_height - 10);
	end
end

--遍历游戏棋盘
function ts_lian_shot()
	keepScreen(true);
	co = 0;
	local i,j,t,r,g,b = 0, 0, 0, 0, 0, 0;
	for i = 2, p_counts_x + 1, 1 do
		for j = 2, p_counts_y + 1, 1 do
			--这儿有方块吗？
			r, g, b = getColorRGB(pos[i][j][1] + p_chkpos_a, pos[i][j][2] + p_chkpos_b);
			if r >= 245 and g >= 245 then
				--这儿似乎有可用方块！
				co = co + 1;
				pos[i][j][3] = 1;
				pos[i][j][4] = {};
				for t = 1, p_sampling, 1 do
					pos[i][j][4][t] = {};
					pos[i][j][4][t][1] = pos[i][j][1] + rand[t][1];
					pos[i][j][4][t][2] = pos[i][j][2] + rand[t][2];
					pos[i][j][4][t][3] = {};
					pos[i][j][4][t][3][1], pos[i][j][4][t][3][2], pos[i][j][4][t][3][3] = getColorRGB(pos[i][j][4][t][1], pos[i][j][4][t][2]);
				end
			elseif g >= 245 then
				--这儿似乎有冰冻方块！
				co = co + 1;
				pos[i][j][3] = 0;
			else
				--这儿没有方块。
				pos[i][j][3] = -1;
			end
		end
	end
	keepScreen(false);
	if co == 0 then
		return false;
	else
		return true;
	end
end

--判断方块是否存在
function isexist(e1, e2)
	if e1 > 0 and e2 > 0 and e1 < p_counts_x + 2 and e2 < p_counts_y + 2 then
		if pos[e1][e2][3] == 1 then
			return 1;
		else
			return 0;
		end
	else
		return -1;
	end
end

--判断方块是否相同
function ts_lian_issame(f1, g1, f2, g2)
	if f1 == f2 and g1 == g2 then
		return -1;
	else
		if f1 < 1 or f1 > p_counts_x + 2 or g1 < 1 or g1 > p_counts_y + 2 or f2 < 1 or f2 > p_counts_x + 2 or g2 < 1 or g2 > p_counts_y + 2 then
			return -1;
		else
			if isexist(f1, g1) == 1 and isexist(f2, g2) == 1 then
				--这一块需要谨慎控制，因为棋盘游戏动画略多，容易误判，要尽量减少误判概率就需要在性能和准确度上配置平衡。
				local i, same_num, g_check = 0, 0, 0;
				for i = 1, p_sampling, 1 do
					if pos[f1][g1][4][i][3][1] >= pos[f2][g2][4][i][3][1] - p_precision and pos[f1][g1][4][i][3][1] <= pos[f2][g2][4][i][3][1] + p_precision and pos[f1][g1][4][i][3][2] >= pos[f2][g2][4][i][3][2] - p_precision and pos[f1][g1][4][i][3][2] <= pos[f2][g2][4][i][3][2] + p_precision and pos[f1][g1][4][i][3][3] >= pos[f2][g2][4][i][3][3] - p_precision and pos[f1][g1][4][i][3][3] <= pos[f2][g2][4][i][3][3] + p_precision then
						if pos[f1][g1][4][i][3][1] >= 240 and pos[f1][g1][4][i][3][2] >= 240 and pos[f2][g2][4][i][3][1] >= 240 and pos[f2][g2][4][i][3][2] >= 240 then
							--比对的这两个位置是没有方块标志的
							g_check = g_check + 1;
						end
						same_num = same_num + 1;
					end
				end
				if g_check >= (p_sampling - 2) then
					--如果采样点的方块标志几乎不存在，则判定为动画效果中尚未翻转的方块。
					return 0;
				end
				if same_num >= (p_sampling / 2) then
					return 1;
				else
					return 0;
				end
			else
				return -1;
			end
		end
	end
end

--判断方块是否相邻
function beside(b1, c1, b2, c2)
	if isexist(b1, c1) == 1 and isexist(b2, c2) == 1 then
		if b1 == b2 or c1 == c2 then
			if b1 == b2 and c2 == c2 then
				return false;
			else
				if b1 == b2 then
					if c1 - c2 == 1 or c2 - c1 == 1 then
						return true;
					else
						return false;
					end
				else
					if b1 - b2 == 1 or b2 - b1 == 1 then
						return true;
					else
						return false;
					end
				end
			end
		else
			return false;
		end
	else
		return false;
	end
end

--判断单线是否连通
function la(m1, n1, m2, n2)
	if beside(m1, n1, m2, n2) == true then
		return true;
	else
		if m1 == m2 or n1 == n2 then
			if m1 == m2 and n1 == n2 then
				return false;
			else
				if m1 == m2 then
					if n1 > n2 then
						amin, amax = n2 + 1, n1 - 1;
					else
						amin, amax = n1 + 1, n2 - 1;
					end
					for ai = amin,amax do
						if isexist(m1,ai) ~= 0 then
							return false;
						end
					end
				else
					if m1 > m2 then
						amin, amax = m2 + 1, m1 - 1;
					else
						amin, amax = m1 + 1, m2 - 1;
					end
					for ai = amin,amax do
						if isexist(ai,n1) ~= 0 then
							return false;
						end
					end
				end
			end
			return true;
		else
			return false;
		end
	end
end

--判断双线是否连通
function lb(m3, n3, m4, n4)
	if la(m3, n3, m4, n4) == true then
		return true;
	else
		if la(m3, n3, m3, n4) == true and la(m3, n4, m4, n4) == true and isexist(m3, n4) == 0 then
			return true;
		else
			if la(m3, n3, m4, n3) == true and la(m4, n3, m4, n4) == true and isexist(m4, n3) == 0 then
				return true;
			else
				return false;
			end
		end
	end
end

--判断三线是否连通
function ts_lian_access(m5, n5, m6, n6)
	if lb(m5, n5, m6, n6) == true then
		return true;
	else
		if isexist(m5, n5) == 1 and isexist(m6, n6) == 1 then
			for ia = 1,p_counts_x + 2 do
				if la(ia, n5, m5, n5) == true and lb(ia, n5, m6, n6) == true and isexist(ia, n5) == 0 then
					return true;
				end
			end
			for ib = 1,p_counts_y + 2 do
				if la(m5, ib, m5, n5) == true and lb(m5, ib, m6, n6) == true and isexist(m5, ib) == 0 then
					return true;
				end
			end
			return false;
		else
			return false;
		end
	end
end

--执行模拟触摸
function ts_lian_click(clx, cly)
	if isexist(clx, cly) == 1 then
    touchDown(1, pos[clx][cly][1] + p_chkpos_a, pos[clx][cly][2] + p_chkpos_b);
		--重置方块状态
		pos[clx][cly][3] = -1
		touchUp(1, pos[clx][cly][1] + p_chkpos_a, pos[clx][cly][2] + p_chkpos_b);
	end
end

--脚本初始化
function ts_lian_init()
	if ts_lian_load_set() == true then
		dialog("天天星连萌经典模式脚本 For TouchSprite\n版本 2.0 Beta\n编写：i_82（357722984）\n\n单击＂准备＂后 " .. STARTING_DELAY .. " 秒后开始运行。\n\n因使用本脚本所造成的一切后果（包括但不限于分数无效、封号），请使用者自行承担。\n威锋网测试组出品", GREETINGS_DELAY);
		mSleep(STARTING_DELAY * 1000);
		ts_lian_makepos();
		return true;
	else
		dialog("错误\n\n此脚本仅适用于 iPhone 4+、iPod Touch 5+，脚本即将终止运行。⚠", GREETINS_DELAY);
		return false;
	end
end

--前台应用检查
function ts_frontapp()
	local time_now = os.time();
	if (time_now - time_origin) <= CHK_FRONT_APP_DELAY then
		return true;
	else
		time_origin = time_now;
		front_app = frontAppBid();
		if front_app ~= APP_IDENTIFIER then
			return false;
		else
			return true;
		end
	end
end

--前台应用失败
function ts_lian_stop()
	dialog("请确保天天星连萌游戏已启动并处于前台，脚本即将终止运行。", GREETINGS_DELAY);
	lua_exit();
end

--主循环
function ts_lian()
	time_origin = os.time();
	while ts_frontapp() == true do
		if ts_lian_shot() == true then
			local u1, v1, u2, v2 = 0, 0, 0, 0;
			for u1 = 2, p_counts_x + 1, 1 do
				for v1 = 2, p_counts_y + 1, 1 do
					for u2 = 2, p_counts_x + 1, 1 do
						for v2 = 2, p_counts_y + 1, 1 do
							if ts_lian_issame(u1, v1, u2, v2) == 1 then
								if ts_lian_access(u1, v1, u2, v2) == true then
									ts_lian_click(u1, v1);
									ts_lian_click(u2, v2);
									mSleep(CLICK_DELAY);
								end
							end
						end
					end
				end
			end
		end
		mSleep(ROUND_DELAY);
	end
	ts_lian_stop();
end

--启动脚本
function main()
	if ts_lian_init() == true then
		ts_lian();
	else
		lua_exit();
	end
end

main();
