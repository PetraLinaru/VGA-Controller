library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity VGA_CTRL is
  	port( CLK : in std_logic;
	SEL_COL : in std_logic_vector (2 downto 0);
	SEL_FORM : in std_logic_vector(1 downto 0);	
	RESET : in  std_logic;
	EN_MOVE: in std_logic;
	BUTTON1,BUTTON2,BUTTON3,BUTTON4: in std_logic;
	VGA_R: out std_logic_vector (3 downto 0);
	VGA_G:out std_logic_vector (3 downto 0);
	VGA_B: out std_logic_vector (3 downto 0);
	H_SYNC : out std_logic;
	V_SYNC : out std_logic);
end VGA_CTRL;

architecture Behavioral of VGA_CTRL is


signal CLK25: std_logic:='0'; 
signal CLK_CONTROL: std_logic:='0';


--valorile pentru sincronizarea counterelor si pentru obtinerea semnalelor H_SYNC 	
constant H_DISP: integer :=639;
constant H_FRONT_PORCH : integer := 16;
constant H_SYNC_PULSE: integer :=96;   
constant H_BACK_PORCH : integer := 48;	
constant H_TOTAL :integer :=799;

--valorile pentru frame-ul in care vom incadra formele pe axa orizontala
signal H_Form_F : integer :=130;
signal H_Form_I : integer :=10 ;
signal H_Form_F_i : integer :=130;
signal H_Form_I_i : integer :=10 ;


--valorile pentru sincronizarea counterelor si pentru obtinerea semnalelor V_SYNC 
constant V_DISP: integer :=479;
constant V_FRONT_PORCH : integer :=10;
constant V_SYNC_PULSE : integer	:= 2;
constant V_BACK_PORCH : integer :=33;
constant V_TOTAL:integer :=524;


--valorile pentru frame-ul in care vom incadra formele pe axa verticala
signal V_Form_F : integer:=130 ;
signal V_Form_I : integer:=10 ;
signal V_Form_F_i : integer:=130 ;
signal V_Form_I_i : integer:=10 ;

--semnale pentru asignarea culorilor
signal i_VGA_R : std_logic_vector(3 downto 0);
signal i_VGA_G: std_logic_vector (3 downto 0);
signal i_VGA_B : std_logic_vector(3 downto 0);

--semnale pentru miscarea formei pe ecran
signal H_INC : integer :=0;
signal V_INC: integer :=0;

--semnale pentru pozitia formei pe ecran
signal H_POS: integer :=0;
signal V_POS: integer :=0; 


signal Display: std_logic :='0';
--constant Delay : integer := 650000; -- 6.5ms
--signal countmov : integer := 0;
--signal btn_tmp : std_logic := '0';
--signal btn1_debounced : std_logic;
--signal btn2_debounced : std_logic;
--constant c_DEBOUNCE_LIMIT : integer := 250000;
--signal r_Count : integer range 0 to c_DEBOUNCE_LIMIT := 0;
--signal r_State : std_logic := '0';
--signal r2_Count : integer range 0 to c_DEBOUNCE_LIMIT := 0;
--signal r2_State : std_logic := '0';


type stare_form is (form1,form2,form3,form4);
signal assigned_form  : stare_form;
--form1 : patrat 50x50
--form2 : dreptunghi 90x40
--form3: 3 linii verticale
--form4: broasca cu breton

begin	
--UC:
Codificator: --Ana 
process(SEL_COL)
	begin
			if(SEL_COL="000")then 
			 i_VGA_R<="0000";
			 i_VGA_G<="0000";
			 i_VGA_B<="0000";	
			elsif(SEL_COL="001")then 
			 i_VGA_R<="1001";
			 i_VGA_G<="0011";
			 i_VGA_B<="1011";	
			elsif(SEL_COL="010")then
			 i_VGA_R<="0001";
			 i_VGA_G<="1110";
			 i_VGA_B<="0101";	
			elsif(SEL_COL="100")then
			 i_VGA_R<="1000";
			 i_VGA_G<="0100";
			 i_VGA_B<="0000";
			elsif(SEL_COL="110")then
			 i_VGA_R<="1011";
			 i_VGA_G<="0000";
			 i_VGA_B<="1000";	
			elsif(SEL_COL="011")then
			 i_VGA_R<="1001";
			 i_VGA_G<="1101";
			 i_VGA_B<="0000";	
	        elsif(SEL_COL="101")then
			 i_VGA_R<="0001";
			 i_VGA_G<="0110";
			 i_VGA_B<="0100";	
			elsif(SEL_COL="111")then
			 i_VGA_R<="1111";
			 i_VGA_G<="1111";
			 i_VGA_B<="1111";
			end if;
end process;


Form_Memory: process(SEL_FORM)--Petra
begin
case (SEL_FORM) is

when "00" => assigned_form<=form1;
when "01" => assigned_form<=form2;
when "10"=>assigned_form<=form3;
when others =>assigned_form<=form4;


end case; 
end process;
			
-- UE:

Fr_Divider:	  --Ana
process(CLK)
variable count: std_logic_vector(1 downto 0):="00";
variable tmp : std_logic ;
begin
 tmp:=CLK25;
 if(CLK='1' and CLK'event) then
  count:=count+1;
  if (count="10") then 
  tmp:=not tmp;
  count:=(others=>'0');
  end if;
  end if;
  CLK25<=tmp;
  end process;
  
  
Fr_Divider2:--Petra
process(CLK)
variable count2: std_logic_vector(18 downto 0):="0000000000000000000";
variable tmp2 : std_logic ;
begin
 tmp2:=CLK_CONTROL;
 if(CLK='1' and CLK'event) then
  count2:=count2+1;
  if (count2="1000000000000000000") then  
  tmp2:=not tmp2;
  count2:=(others=>'0');
  end if;
  end if;
  CLK_CONTROL<=tmp2;
  end process;
  

	

	
-- Counter pentru a obtine pozitia pe linia orizontala si pentru a putea crea frame-ul
H_POS_Counter: 	 --Petra
process(RESET, CLK25)
begin
if (RESET='1')then 
	H_POS<=0;	  
elsif (CLK25'EVENT and CLK25='1')then
	if (H_POS=H_DISP+H_FRONT_PORCH+H_SYNC_PULSE+H_BACK_PORCH) then
		H_POS<=0;	  
	else
		H_POS<=H_POS+1;
	end if;
	end if;	 
end process;  



--Counter pentru a obtine pozitia pe linia verticala signal pentru a putea crea frame-ul
V_POS_Counter: process(RESET, CLK25)  --Petra
begin
if (RESET='1')then 
	V_POS<=0;	  
elsif (CLK25'EVENT and CLK25='1') then
    if (H_POS=H_DISP+H_FRONT_PORCH+H_SYNC_PULSE+H_BACK_PORCH) then
    if (V_POS=V_DISP+V_FRONT_PORCH+V_SYNC_PULSE+V_BACK_PORCH)	then
		V_POS<=0;	  
	   else
		V_POS<=V_POS+1;
		end if;
	end if;
	end if;
end process;   



--genetator H_SYNC pe baza organigramei din documentatie
H_SYNC_Generator:	   --Petra
process(RESET,CLK25,H_POS)
begin
if (RESET='1')then 
	H_SYNC<='0';	  
elsif (CLK25'EVENT and CLK25='1')then
	if((H_POS<=H_DISP+H_FRONT_PORCH)or (H_POS>H_DISP+H_FRONT_PORCH+H_SYNC_PULSE)) then
		 H_SYNC<='1';	 
	else H_SYNC<='0';  
	end if;
	end if;
end process;  



-- generator V_SYNC pe baza organigramei din documentatie	
V_SYNC_Generator: --Petra
process(RESET,CLK25,V_POS)
begin
if (RESET='1')then 
	V_SYNC<='0';	  
elsif (CLK25'EVENT and CLK25='1')then
	if((V_POS<=V_DISP+V_FRONT_PORCH)or (V_POS>V_DISP+V_FRONT_PORCH+V_SYNC_PULSE))
		then V_SYNC<='1';	 
	else V_SYNC<='0';  
	end if;
	end if;
end process;

--Circuit care identifica pe baza unor conditii daca pixel-ul se afla in frame-ul imaginii
--si daca poate fi colorat
DisplayS: process(CLK25,RESET,H_POS,V_POS)--Petra
begin
if(RESET='1')then
   Display<='0';
   elsif(CLK25'EVENT and CLK25='1') then
   if(H_POS<=H_DISP and V_POS<=V_DISP)then
   Display<='1';
   else 
   Display<='0';
   end if;
   end if;
   end process;
   

--Circuit pentru miscarea imaginii si controlul miscarii
Control_Move: process(RESET,BUTTON1,BUTTON2,BUTTON3, CLK_CONTROL,EN_MOVE,Display,H_INC,V_INC,H_POS,V_POS)--Ana si Petra
begin
	if(RESET='1') then 
	H_INC<=0;
	V_INC<=0;
	elsif (CLK_CONTROL'EVENT and CLK_CONTROL='1') then 
	if(EN_MOVE='1') then 

	    if((BUTTON1='1')and ((H_INC+H_POS)>=0 or (H_INC+H_POS)<=H_DISP))then 
		  H_INC<=H_INC+1;
		  else 
		     if((BUTTON2='1')and ((H_INC+H_POS)>=0 or (H_INC+H_POS)<=H_DISP)) then 
		H_INC<=H_INC-1;
		else if ((BUTTON3='1')and ((V_INC+V_POS)>=0 or (V_INC+V_POS)<=V_DISP)) then
		V_INC<=V_INC-1;
		else if ((BUTTON4='1')and ((V_INC+V_POS)>=0 or (V_INC+V_POS)<=V_DISP)) then
		V_INC<=V_INC+1;
		end if;					 
	end if;
    end if;   
    end if;
    end if;
    end if;                 
               
end process;


--Circuitul care verirfica conditiile pentru fiecare forma in parte si stabileste daca pixel-ul 
--trebuie colorat sau nu
Pattern_Generator: --Petra
process(RESET,CLK25,Display,H_Form_I,V_Form_I,H_Form_F,V_Form_F,assigned_form,H_INC,V_INC)
begin
   if(RESET='1') then
    VGA_R<="0000";
	VGA_G<="0000";
	VGA_B<="0000";

	else
		if(CLK25'EVENT and CLK25='1') then
		if(Display='1')then
		  if((H_POS>=(H_Form_I+H_INC) and H_POS<=(H_Form_F+H_INC))and (V_POS>=(V_Form_I+V_INC) and V_POS<=(V_Form_F+V_INC))) then 
			case (assigned_form) is
				when form1 => 
				if((H_POS>=(30+H_INC) and H_POS<=(80+H_INC)) and (V_POS>=(30+V_INC) and V_POS<=(80+V_INC))) then-- patrat
				VGA_R<=i_VGA_R;
			    VGA_G<=i_VGA_G;
			    VGA_B<=i_VGA_B;
			    else 
			     VGA_R<="0000";
	             VGA_G<="0000";
	             VGA_B<="0000";
	             end if;
    
			 when form2=>
			 if((H_POS>= (11+H_INC) and H_POS<=(101+H_INC)) and (V_POS>=(11+V_INC) and V_POS<=(51+V_INC)))then  --dreptunghi
			 VGA_R<=i_VGA_R;
			    VGA_G<=i_VGA_G;
			    VGA_B<=i_VGA_B;
			    else 
			     VGA_R<="0000";
	             VGA_G<="0000";
	             VGA_B<="0000";
			    end if;
			    when form3=> --linii
			    if((H_POS>=(11+H_INC) and H_POS<=(31+H_INC) and V_POS>=(11+V_INC) and V_POS<=(101+V_INC)) or (H_POS>= (51+H_INC) and H_POS <= (71+H_INC) and V_POS>=(11+V_INC) and V_POS<=(101+V_INC)) or (H_POS>= (91+H_INC) and H_POS <= (111+H_INC) and V_POS>=(11+V_INC) and V_POS<=(101+V_INC))) then
			    VGA_R<=i_VGA_R;
			    VGA_G<=i_VGA_G;
			    VGA_B<=i_VGA_B;
			    else 
			     VGA_R<="0000";
	             VGA_G<="0000";
	             VGA_B<="0000";
			    end if;
			    when form4=>  --broasca cu breton
			    if(V_POS<17+V_INC) then
			  		 VGA_R<="0000";
			  		VGA_G<="0000";
	          		VGA_B<="0000"; 
					elsif(V_POS<(17+V_INC) and V_POS<(41+V_INC)) then 
			 				 if(H_POS<(65+H_INC)) then
			 					 VGA_R<="0000";
			  					 VGA_G<="0000";
	          					 VGA_B<="0000"; 
							 elsif(H_POS>=(65+H_INC) and H_POS<(120+H_INC))then	
									 VGA_R<=i_VGA_R;
									 VGA_G<=i_VGA_G;
			 						 VGA_B<=i_VGA_B;
							elsif(H_POS>=(120+H_INC)) then 
			 						VGA_R<="0000";
			  						VGA_G<="0000";
	                				VGA_B<="0000";
							end if;
		 			elsif(V_POS>=(41+V_INC) and V_POS<(43+V_INC))then 
							if(H_POS<(65+H_INC)) then
								  VGA_R<="0000";
								  VGA_G<="0000";
						          VGA_B<="0000";
							elsif(H_POS>=(41+H_INC) and H_POS<(74+H_INC))then
								 VGA_R<=i_VGA_R;
								 VGA_G<=i_VGA_G;
								 VGA_B<=i_VGA_B;	  
							elsif(H_POS>=(74+H_INC) and H_POS<(76+H_INC))then
								 VGA_R<="0000";
								 VGA_G<="0000";
								 VGA_B<="0000";
							elsif(H_POS>=(76+H_INC) and H_POS<(H_INC+109))then
								 VGA_R<=i_VGA_R;
								 VGA_G<=i_VGA_G;
								 VGA_B<=i_VGA_B;
						    elsif(H_POS>=(109+H_INC) and H_POS<(111+H_INC))then
					             VGA_R<="0000";
								 VGA_G<="0000";
								 VGA_B<="0000";
			                     elsif(H_POS>=(111+H_INC) and H_POS<(120+H_INC))then
			                     VGA_R<=i_VGA_R;
								 VGA_G<=i_VGA_G;
								 VGA_B<=i_VGA_B;
								 
			                          
						     elsif(H_POS>=(120+H_INC))then
							     VGA_R<="0000";
								 VGA_G<="0000";
								 VGA_B<="0000";	
							end if;	
					elsif(V_POS>=(43+V_INC) and V_POS<(61+V_INC))then
							if(H_POS<(65+H_INC)) then
								VGA_R<="0000";
								VGA_G<="0000";
							    VGA_B<="0000";	
						    elsif(H_POS>=(65+H_INC) and H_POS<(120+H_INC))then
					            VGA_R<=i_VGA_R;
								VGA_G<=i_VGA_G;
							    VGA_B<=i_VGA_B;	
							elsif(H_POS>=(120+H_INC))then
								VGA_R<="0000";
							    VGA_G<="0000";
								VGA_B<="0000";
	 						end if;
				  elsif(V_POS>=(61+V_INC) and V_POS<(62+V_INC))then
							 if(H_POS<(65+H_INC))then
								 VGA_R<="0000";
								 VGA_G<="0000";
								 VGA_B<="0000";
							elsif(H_POS>=(65+H_INC) and H_POS<(74+H_INC))then
								 VGA_R<=i_VGA_R;
								 VGA_G<=i_VGA_G;
								 VGA_B<=i_VGA_B;				
							elsif (H_POS>=(74+H_INC) and H_POS<(111+H_INC))then 
								 VGA_R<="0000";
								 VGA_G<="0000";
								 VGA_B<="0000";
							elsif(H_POS>=(111+H_INC) and H_POS<(120+H_INC))then
								 VGA_R<=i_VGA_R;
								 VGA_G<=i_VGA_G;
								 VGA_B<=i_VGA_B;
		
							elsif(H_POS>=(120+H_INC)) then
								 VGA_R<="0000";
								 VGA_G<="0000";
								 VGA_B<="0000";
							end if;
					elsif(V_POS>=(61+V_INC) and V_POS<(82+V_INC))then
							if(H_POS<(65+H_INC))then
								 VGA_R<="0000";
								 VGA_G<="0000";
								 VGA_B<="0000";
							elsif(H_POS>=(65+H_INC) and H_POS<(120+H_INC))then
							     VGA_R<=i_VGA_R;
								 VGA_G<=i_VGA_G;
								 VGA_B<=i_VGA_B;			
						   elsif(H_POS>=(120+H_INC))then
							         VGA_R<="0000";
									 VGA_G<="0000";
									 VGA_B<="0000";
						   elsif(H_POS<=(82+H_INC))then
							         VGA_R<="0000";
									 VGA_G<="0000";
									 VGA_B<="0000";
							end if;
					end if;
		

			    end case;
			 		 
		else 		
	VGA_R<="0000";
	VGA_G<="0000";
	VGA_B<="0000"; 
		end if;
	end if;
	end if;
	end if;
	end process;

--Debouncer- NU functioneaza
--BUTTON1_Debounce : process (CLK25,BUTTON1) is
--  begin
--    if rising_edge(CLK25) then  
--      if (BUTTON1 /= r_State and r_Count < c_DEBOUNCE_LIMIT) then
--        r_Count <= r_Count + 1;
--      elsif r_Count = c_DEBOUNCE_LIMIT then
--        r_State <= BUTTON1;
--        r_Count <= 0;
--      else
--        r_Count <= 0;
 
--      end if;
--    end if;
--  end process;
--  btn1_debounced<=r_State;
  
--  BUTTON2_Debounce : process (CLK25,BUTTON2) is
--  begin
--    if rising_edge(CLK25) then  
--      if (BUTTON2 /= r2_State and r2_Count < c_DEBOUNCE_LIMIT) then
--        r2_Count <= r2_Count + 1;
--      elsif r2_Count = c_DEBOUNCE_LIMIT then
--        r2_State <= BUTTON2;
--        r2_Count <= 0;
--      else
--        r2_Count <= 0;
       
 
--      end if;
--    end if;
--  end process;
--  btn2_debounced<=r2_State;


end Behavioral;