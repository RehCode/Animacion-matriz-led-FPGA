library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity mover is
    Port ( clk, sw_reset, pb1: in  STD_LOGIC;
           clk_out, load_out, data_out  : out  STD_LOGIC);
end mover;

architecture Behavioral of mover is
signal dataArray : std_logic_vector(15 downto 0):=x"0B07";
signal dataOutCount : std_logic_vector(4 downto 0):="00000" ;
signal load     : std_logic := '1';
signal salidaDato : std_logic := '0';
type estados is (initcolumnas, encender, borrar, dibujar, dibujarFlechas, dibujaCuadro, dibujarDigitos, dibujarOjo);
signal presente: estados;

type mem4x8x8 is array (0 to 3, 0 to 7) of std_logic_vector(7 downto 0);
constant memoria_cuadro : mem4x8x8 :=
((x"00",x"00",x"00",x"18",x"18",x"00",x"00",x"00"),
 (x"00",x"00",x"3C",x"24",x"24",x"3C",x"00",x"00"),
 (x"00",x"7E",x"42",x"42",x"42",x"42",x"7E",x"00"),
 (x"FF",x"81",x"81",x"81",x"81",x"81",x"81",x"FF"));

constant memoria_flechas : mem4x8x8 :=
((x"08",x"0C",x"FE",x"FF",x"FE",x"0C",x"08",x"00"),
 (x"38",x"38",x"38",x"38",x"FE",x"7C",x"38",x"10"),
 (x"10",x"30",x"7F",x"FF",x"7F",x"30",x"10",x"00"),
 (x"10",x"38",x"7C",x"FE",x"38",x"38",x"38",x"38"));


type mem10x8x8 is array (0 to 9, 0 to 7) of std_logic_vector(7 downto 0);
constant memoria_digitos : mem10x8x8 :=
(("00010000", "00110000", "00010000", "00010000", "00010000", "00010000", "00010000", "00111000"),
 ("00111000", "01000100", "00000100", "00000100", "00001000", "00010000", "00100000", "01111100"),
 ("00111000", "01000100", "00000100", "00011000", "00000100", "00000100", "01000100", "00111000"),
 ("00000100", "00001100", "00010100", "00100100", "01000100", "01111100", "00000100", "00000100"),
 ("01111100", "01000000", "01000000", "01111000", "00000100", "00000100", "01000100", "00111000"),
 ("00111000", "01000100", "01000000", "01111000", "01000100", "01000100", "01000100", "00111000"),
 ("01111100", "00000100", "00000100", "00001000", "00010000", "00100000", "00100000", "00100000"),
 ("00111000", "01000100", "01000100", "00111000", "01000100", "01000100", "01000100", "00111000"),
 ("00111000", "01000100", "01000100", "01000100", "00111100", "00000100", "01000100", "00111000"),
 ("00111000", "01000100", "01000100", "01000100", "01000100", "01000100", "01000100", "00111000"));

type mem8x8x8 is array (0 to 7, 0 to 7) of std_logic_vector(7 downto 0);
constant memoria_bateria : mem8x8x8 :=

((x"44",x"82",x"82",x"82",x"82",x"82",x"82",x"82"),
 (x"44",x"82",x"82",x"82",x"82",x"82",x"82",x"BA"),
 (x"44",x"82",x"82",x"82",x"82",x"BA",x"82",x"BA"),
 (x"44",x"82",x"82",x"BA",x"82",x"BA",x"82",x"BA"),
 (x"44",x"BA",x"82",x"BA",x"82",x"BA",x"82",x"BA"),
 (x"44",x"82",x"82",x"BA",x"82",x"BA",x"82",x"BA"),
 (x"44",x"82",x"82",x"82",x"82",x"BA",x"82",x"BA"),
 (x"44",x"82",x"82",x"82",x"82",x"82",x"82",x"BA"));

constant memoria_ojo : mem8x8x8 :=
((x"18",x"66",x"CF",x"8D",x"81",x"C3",x"66",x"18"),
 (x"18",x"66",x"C3",x"8D",x"8D",x"C3",x"66",x"18"),
 (x"18",x"66",x"C3",x"99",x"99",x"C3",x"66",x"18"),
 (x"18",x"66",x"C3",x"B1",x"B1",x"C3",x"66",x"18"),
 (x"18",x"66",x"F3",x"B1",x"81",x"C3",x"66",x"18"),
 (x"18",x"66",x"DB",x"99",x"81",x"C3",x"66",x"18"),
 (x"00",x"1A",x"26",x"4E",x"40",x"24",x"18",x"00"), -- flecha circular
 (x"0E",x"1C",x"38",x"70",x"38",x"1C",x"0E",x"00")); -- flecha simple

begin

salida_datos : process( clk, pb1 )
variable memCol : integer range 0 to 8;
variable memRow : integer range 0 to 21;
variable conteoReloj : integer range 0 to 5000;
variable delta : integer range 0 to 100;
    variable sprite : integer range 0 to 5;
    variable delta2 : integer range 0 to 1200;
    constant retraso : integer := 1200;
begin
    if rising_edge(clk) then
        if sw_reset = '1' then
            presente <= initcolumnas;
            dataOutCount <= (others => '0');
            load <= '1';
            memCol := 0;
            conteoReloj := 0;
            memRow := 0;
            sprite := 0;
            delta := 0;
        else
            dataOutCount <= dataOutCount + 1;
            if dataOutCount <= "01111" then
                salidaDato <= dataArray(15);
                dataArray <= dataArray(14 downto 0) & dataArray(15);
            end if;

            if dataOutCount >= "10000" then
                load <= '1';
            else
                load <= '0';
            end if;

            if dataOutCount = "11001" then -- 13 "10011" 25 "11001"
                dataOutCount <= (others => '0');

                case( presente ) is
                    when initcolumnas =>
                        dataArray <= x"0B07"; -- activar columnas
                        presente <= encender;
                    when encender =>
                        dataArray <= x"0C01"; -- encender
                        presente <= borrar;
                    when borrar =>
                        dataArray <= x"0" & CONV_STD_LOGIC_VECTOR(memCol + 1, 4) & x"00";
                        memCol := memCol + 1;
                        if memCol = 8 then
                            memCol := 0;
                            presente <= dibujar;
                        end if ;
                    when dibujar =>
                        dataArray <= x"0" & CONV_STD_LOGIC_VECTOR(memCol + 1, 4) & memoria_bateria(memRow, memCol);
                        memCol := memCol + 1;

                        if memCol = 8 then
                            memCol := 0;
                            conteoReloj := conteoReloj + 1;
                        end if;

                        -- 25*5=50
                        if conteoReloj = 15 then
                            conteoReloj := 0;
                            memRow := memRow + 1;
                            if memRow = 8 then
                                memRow := 0;

                                if sprite = 0 then
                                    presente <= dibujar;
                                    memCol := 0;
                                    conteoReloj := 0;
                                elsif sprite = 1 then
                                    presente <= dibujarFlechas;
                                    memCol := 0;
                                    conteoReloj := 0;
                                elsif sprite = 2 then
                                    presente <= dibujaCuadro;
                                    memCol := 0;
                                    conteoReloj := 0;
                                elsif sprite = 3 then
                                    presente <= dibujarDigitos;
                                    memCol := 0;
                                    conteoReloj := 0;
                                else
                                    presente <= dibujarOjo;
                                    memCol := 0;
                                    conteoReloj := 0;
                                end if;

                            end if;
                        end if ;


                    when dibujarFlechas =>
                        dataArray <= x"0" & CONV_STD_LOGIC_VECTOR(memCol + 1, 4) & memoria_flechas(memRow, memCol);
                        memCol := memCol + 1;

                        if memCol = 8 then
                            memCol := 0;
                            conteoReloj := conteoReloj + 1;
                        end if;


                        -- 25*5=50
                        if conteoReloj = 25 then
                            conteoReloj := 0;
                            memRow := memRow + 1;
                            if memRow = 4 then
                                memRow := 0;
                                if sprite = 0 then
                                    presente <= dibujar;
                                    memCol := 0;
                                    conteoReloj := 0;
                                elsif sprite = 1 then
                                    presente <= dibujarFlechas;
                                    memCol := 0;
                                    conteoReloj := 0;
                                elsif sprite = 2 then
                                    presente <= dibujaCuadro;
                                    memCol := 0;
                                    conteoReloj := 0;
                                elsif sprite = 3 then
                                    presente <= dibujarDigitos;
                                    memCol := 0;
                                    conteoReloj := 0;
                                else
                                    presente <= dibujarOjo;
                                    memCol := 0;
                                    conteoReloj := 0;
                                end if;
                            end if;
                        end if ;


                    when dibujaCuadro =>
                        dataArray <= x"0" & CONV_STD_LOGIC_VECTOR(memCol + 1, 4) & memoria_cuadro(memRow, memCol);
                        memCol := memCol + 1;

                        if memCol = 8 then
                            memCol := 0;
                            conteoReloj := conteoReloj + 1;
                        end if;

                        if memRow = 0 then
                            delta := 1;
                        else
                            delta := 5;
                        end if;

                        -- 25*5=50
                        if conteoReloj = delta then
                            conteoReloj := 0;
                            memRow := memRow + 1;
                            if memRow = 2 then
                                memRow := 0;
                                if sprite = 0 then
                                    presente <= dibujar;
                                    memCol := 0;
                                    conteoReloj := 0;
                                elsif sprite = 1 then
                                    presente <= dibujarFlechas;
                                    memCol := 0;
                                    conteoReloj := 0;
                                elsif sprite = 2 then
                                    presente <= dibujaCuadro;
                                    memCol := 0;
                                    conteoReloj := 0;
                                elsif sprite = 3 then
                                    presente <= dibujarDigitos;
                                    memCol := 0;
                                    conteoReloj := 0;
                                else
                                    presente <= dibujarOjo;
                                    memCol := 0;
                                    conteoReloj := 0;
                                end if;

                            end if;
                        end if ;

                    when dibujarDigitos =>
                        dataArray <= x"0" & CONV_STD_LOGIC_VECTOR(memCol + 1, 4) & memoria_digitos(memRow, memCol);
                        memCol := memCol + 1;

                        if memCol = 8 then
                            memCol := 0;
                            conteoReloj := conteoReloj + 1;
                        end if;


                        -- 25*5=50
                        if conteoReloj = 25 then
                            conteoReloj := 0;
                            memRow := memRow + 1;
                            if memRow = 10 then
                                memRow := 0;
                                if sprite = 0 then
                                    presente <= dibujar;
                                    memCol := 0;
                                    conteoReloj := 0;
                                elsif sprite = 1 then
                                    presente <= dibujarFlechas;
                                    memCol := 0;
                                    conteoReloj := 0;
                                elsif sprite = 2 then
                                    presente <= dibujaCuadro;
                                    memCol := 0;
                                    conteoReloj := 0;
                                elsif sprite = 3 then
                                    presente <= dibujarDigitos;
                                    memCol := 0;
                                    conteoReloj := 0;
                                else
                                    presente <= dibujarOjo;
                                    memCol := 0;
                                    conteoReloj := 0;
                                end if;
                            end if;
                        end if ;
                        --- aniadido
                    when dibujarOjo =>
                        dataArray <= x"0" & CONV_STD_LOGIC_VECTOR(memCol + 1, 4) & memoria_ojo(memRow, memCol);
                        memCol := memCol + 1;

                        if memCol = 8 then
                            memCol := 0;
                            conteoReloj := conteoReloj + 1;
                        end if;


                        -- 25*5=50
                        if conteoReloj = 25 then
                            conteoReloj := 0;
                            memRow := memRow + 1;
                            if memRow = 8 then
                                memRow := 0;
                                if sprite = 0 then
                                    presente <= dibujar;
                                    memCol := 0;
                                    conteoReloj := 0;
                                elsif sprite = 1 then
                                    presente <= dibujarFlechas;
                                    memCol := 0;
                                    conteoReloj := 0;
                                elsif sprite = 2 then
                                    presente <= dibujaCuadro;
                                    memCol := 0;
                                    conteoReloj := 0;
                                elsif sprite = 3 then
                                    presente <= dibujarDigitos;
                                    memCol := 0;
                                    conteoReloj := 0;
                                else
                                    presente <= dibujarOjo;
                                    memCol := 0;
                                    conteoReloj := 0;
                                end if;
                            end if;
                        end if ;
                    when others =>
                        presente <= initcolumnas;
                end case ;
            end if;
        end if;

        if pb1 = '0' then
            delta2 := delta2 + 1;
            if delta2 = retraso then
                delta2 := 0;
                if pb1 = '0' then
                    sprite := sprite + 1;
                    if sprite = 5 then
                        sprite := 0;
                    end if;
                end if;
            end if;
        end if;

    end if;

end process salida_datos;

clk_out <= clk;
load_out <= load;
data_out <= salidaDato;

end Behavioral;
