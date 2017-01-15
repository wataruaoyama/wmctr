Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY wmctr IS
PORT(
	RESET : in std_logic;
	XDSD : in std_logic;
	LRCK : in std_logic;
	BCK : in std_logic;
	DATA0 : in std_logic;	-- DSDL
	DATA1 : in std_logic;
	CPOK : in std_logic;
	CLK_SEL : in std_logic;
	CLK22M : in std_logic;
	CLK24M : in std_logic;
	ZFLAG : in std_logic;
	LRCKDSDL : out std_logic;
	DIN : out std_logic;
	BCKDSD64 : out std_logic;
	BBB_MCK : out std_logic;
	DAC_SCK : out std_logic;
	OSR : out std_logic;
	SMUTE  : out std_logic;
	MUTEOUT : out std_logic;
	DSD : out std_logic;
	LEDDSD : out std_logic;
	LEDPCM : out std_logic;
	LED96KH : out std_logic;
	EN22M : out std_logic;
	EN24M : out std_logic
	);
END wmctr;

ARCHITECTURE RTL OF wmctr IS

signal sysclk,ld,q,cen : std_logic;
signal cnt : std_logic_vector(8 downto 0);
signal en_fs176,en_fs88,en_fs44,en_fs32,ov96K : std_logic;
signal fs176,fs88,fs44,fs32 : std_logic;

BEGIN

sysclk <= CLK22M when CLK_SEL = '0' else CLK24M;
EN22M <= not CLK_SEL;
EN24M <= CLK_SEL;
BBB_MCK <= sysclk when CPOK = '1' else 'Z';
DAC_SCK <= sysclk when CPOK = '1' else 'Z';

LRCKDSDL <= LRCK when XDSD = '1' else DATA1;
DIN <= DATA0;
BCKDSD64 <= BCK;
DSD <= not XDSD; 
LEDDSD <= XDSD;
LEDPCM <= not XDSD;
--LED96KH <= not ((fs88 or fs176) and CLK_SEL );
LED96KH <= not ov96K;
SMUTE <= RESET;
--MUTEOUT <= not ZFLAG when RESET = '1' else 'Z';
MUTEOUT <= '0' when RESET = '0' else '1';

ld <= LRCK and not q;

process(sysclk,XDSD) BEGIN
	if(XDSD = '0') then
		q <= '1';
	elsif(sysclk'event and sysclk='1') then
		q <= LRCK;
	end if;
end process;

process(sysclk,XDSD) BEGIN
	if(XDSD = '0') then
		cen <= '0';
	elsif(sysclk'event and sysclk='1') then
		if(ld = '1') then
			cen <= '1';
		end if;
	end if;
end process;		

process(sysclk,XDSD) BEGIN
	if(XDSD = '0') then
		cnt <= (others => '0');
	elsif(sysclk'event and sysclk='1') then
		if(cen = '1') then
			if(ld = '1') then
				cnt <= (others => '0');
			elsif(cnt = "111111111") then
				cnt <= "111111111";
			else
				cnt <= cnt + '1';
			end if;
		end if;
	end if;
end process;

process(cnt) begin
	if(cnt = "001000010") then
		en_fs176 <= '1';
	elsif(cnt = "010000010") then
		en_fs88 <= '1';
	elsif(cnt = "100000010") then
		en_fs44 <= '1';
	elsif(cnt = "110000001") then
		en_fs32 <= '1';
	else
		en_fs176 <= '0';
		en_fs88 <= '0';
		en_fs44 <= '0';
		en_fs32 <= '0';
	end if;
end process;	

process(sysclk,XDSD) BEGIN
	if(XDSD = '0') then
		fs176 <= '1';
		fs88 <= '1';
		fs44 <= '1';
		fs32 <= '1';
	elsif(sysclk'event and sysclk='1') then
		if(en_fs176 = '1') then
			if(LRCK = '0') then
				fs176 <= '0';
			else
				fs176 <= '1';
			end if;
		end if;
		
		if(en_fs88 = '1') then
			if(LRCK = '0') then
				fs88 <= '0';
			else
				fs88 <= '1';
			end if;
		end if;
		
		if(en_fs44 = '1') then
			if(LRCK = '0') then
				fs44 <= '0';
			else
				fs44 <= '1';
			end if;
		end if;
		
		if(en_fs32 = '1') then
			if(LRCK = '0') then
				fs32 <= '0';
			else
				fs32 <= '1';
			end if;
		end if;
	end if;
end process;

process (XDSD,fs176,fs88,fs44,fs32,DATA1) BEGIN
	if(XDSD = '0') then
		OSR <= DATA1;
	elsif(fs176 = '0') then
		OSR <= '1';
	elsif(fs88 = '0') then
		OSR <= 'Z';
	elsif(fs44 = '0') then
		OSR <= '0';
	elsif(fs32 = '0') then
		OSR <= '0';
	end if;
end process;
	
process (CLK_SEL,fs176,fs88) begin
	if(CLK_SEL = '1') then
		if(fs88 = '0') then
			ov96K <= '1';
		elsif(fs176 = '0') then
			ov96K <= '1';
		else
			ov96K <= '0';
		end if;
	else
		if(fs176 = '0') then
			ov96K <= '1';
		else
			ov96K <= '0';
		end if;
	end if;
end process;	
	
end RTL;
			
				