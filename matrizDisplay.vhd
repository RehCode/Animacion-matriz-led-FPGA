library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity graficos is
    Port ( clk, sw_reset, pb1: in  STD_LOGIC;
           clk_out, load_out, data_out  : out  STD_LOGIC);
end graficos;

architecture Behavioral of graficos is
signal dataArray : std_logic_vector(15 downto 0):=x"0B07";
signal dataOutCount : std_logic_vector(4 downto 0):="00000" ;
signal load     : std_logic := '1';
signal salidaDato : std_logic := '0';
type estados is (initcolumnas, encender, borrar, dibujar);
signal presente: estados;

 type memIntegers6x2 is array (0 to 5, 0 to 1) of integer range 0 to 50;
 constant memDirecciones : memIntegers6x2 :=
 (
     (0,3),
     (3,3),
     (4,4),
     (5,7),
     (7,14),
     (15,35)
 );

type mem34x8x8 is array (0 to 34, 0 to 7) of std_logic_vector(7 downto 0);
constant memoria_graficos : mem34x8x8 :=

(("00010000", "00110000", "00010000", "00010000", "00010000", "00010000", "00010000", "00111000"), -- digito 1 (0)
 ("00111000", "01000100", "00000100", "00000100", "00001000", "00010000", "00100000", "01111100"), -- digito 2 (1)
 ("00111000", "01000100", "00000100", "00011000", "00000100", "00000100", "01000100", "00111000"), -- digito 3 (2)
 (x"08",x"0C",x"FE",x"FF",x"FE",x"0C",x"08",x"00"), -- flecha izquierda (3)
 (x"38",x"38",x"38",x"38",x"FE",x"7C",x"38",x"10"), -- flecha derecha (4)
 (x"92",x"54",x"38",x"FE",x"38",x"54",x"92",x"00"), -- asterisco 1 (5)
 (x"00",x"00",x"38",x"38",x"38",x"00",x"00",x"00"), -- asterisco 2 (6)
 (x"44",x"82",x"82",x"82",x"82",x"82",x"82",x"82"), -- bateria 1 (7)
 (x"44",x"82",x"82",x"82",x"82",x"82",x"82",x"BA"),
 (x"44",x"82",x"82",x"82",x"82",x"BA",x"82",x"BA"),
 (x"44",x"82",x"82",x"BA",x"82",x"BA",x"82",x"BA"),
 (x"44",x"BA",x"82",x"BA",x"82",x"BA",x"82",x"BA"),
 (x"44",x"82",x"82",x"BA",x"82",x"BA",x"82",x"BA"),
 (x"44",x"82",x"82",x"82",x"82",x"BA",x"82",x"BA"),
 (x"44",x"82",x"82",x"82",x"82",x"82",x"82",x"BA"), -- bateria 8 final (14)
 (x"50",x"38",x"00",x"70",x"08",x"08",x"70",x"00"), -- uach (15)
 (x"38",x"50",x"38",x"00",x"70",x"08",x"08",x"70"),
 (x"00",x"38",x"50",x"38",x"00",x"70",x"08",x"08"),
 (x"30",x"00",x"38",x"50",x"38",x"00",x"70",x"08"),
 (x"48",x"30",x"00",x"38",x"50",x"38",x"00",x"70"),
 (x"48",x"48",x"30",x"00",x"38",x"50",x"38",x"00"),
 (x"00",x"48",x"48",x"30",x"00",x"38",x"50",x"38"),
 (x"78",x"00",x"48",x"48",x"30",x"00",x"38",x"50"),
 (x"10",x"78",x"00",x"48",x"48",x"30",x"00",x"38"),
 (x"78",x"10",x"78",x"00",x"48",x"48",x"30",x"00"),
 (x"00",x"78",x"10",x"78",x"00",x"48",x"48",x"30"),
 (x"08",x"00",x"78",x"10",x"78",x"00",x"48",x"48"),
 (x"00",x"08",x"00",x"78",x"10",x"78",x"00",x"48"),
 (x"00",x"00",x"08",x"00",x"78",x"10",x"78",x"00"),
 (x"78",x"00",x"00",x"08",x"00",x"78",x"10",x"78"),
 (x"08",x"70",x"00",x"00",x"08",x"00",x"78",x"10"),
 (x"08",x"08",x"70",x"00",x"00",x"08",x"00",x"78"),
 (x"70",x"08",x"08",x"70",x"00",x"00",x"08",x"00"),
 (x"00",x"70",x"08",x"08",x"70",x"00",x"00",x"08"),
 (x"38",x"00",x"70",x"08",x"08",x"70",x"00",x"00")); -- uach final (34)

begin

salida_datos : process( clk, pb1 )
    variable memCol : integer range 0 to 8 := 0;
    variable memRow : integer range 0 to 40;
    variable conteoReloj : integer range 0 to 40;
    variable delta : integer range 0 to 100; -- var de boton
    variable delta2 : integer range 0 to 1200; -- var de boton
    constant retraso : integer := 1200; -- var de boton
    variable grafico : integer range 0 to 8;
    variable memOffset : integer range 0 to 40;
    variable memFinal : integer range 0 to 40;
    variable conteoMax : integer range 0 to 40;
begin
    if rising_edge(clk) then
        if sw_reset = '1' then
            dataOutCount <= (others => '0');
            presente <= initcolumnas;
            load <= '1';
            grafico := 0;
            conteoReloj := 0;
            memCol := 0;
            memRow := 0;
        else

            dataOutCount <= dataOutCount + 1;
            if dataOutCount <= "01111" then -- contar y enviar 1 bit
                salidaDato <= dataArray(15);
                dataArray <= dataArray(14 downto 0) & dataArray(15);
            end if;

            if dataOutCount >= "10000" then -- al terminar subir load
                load <= '1';
            else
                load <= '0';
            end if;

            if dataOutCount = "11001" then -- 13 "10011" 25 "11001" cambiar datos
                dataOutCount <= (others => '0');
               
                case( presente ) is
                    when initcolumnas =>
                        dataArray <= x"0B07"; -- activar las 7 columnas
                        presente <= encender;
                    when encender =>
                        dataArray <= x"0C01"; -- encender
                        presente <= borrar;
                    when borrar =>
                        dataArray <= x"0" & CONV_STD_LOGIC_VECTOR(memCol + 1, 4) & x"00"; -- avanza desde la columna 1 enviando ceros
                        memCol := memCol + 1;
                        if memCol = 8 then
                            memCol := 0;
                            presente <= dibujar;
                        end if ;
                    when dibujar =>
        
                        dataArray <= x"0" & CONV_STD_LOGIC_VECTOR(memCol + 1, 4) & memoria_graficos(memOffset + memRow, memCol);
                        
                        memCol := memCol + 1;
                        if memCol = 8 then
                            memCol := 0;
                            conteoReloj := conteoReloj + 1;
                       end if;

                        -- 25*5=50
                        if conteoReloj = 15 then -- espera un tiempo para mostrar el siguiente
                            conteoReloj := 0;
                            
                            memRow := memRow + 1;
                            if memRow >= conteoMax then  -- termino de mostrar todas las imagenes
                                memRow := 0;    -- iniciar de nuevo
                            end if;
                        end if ;

                    when others =>
                        presente <= initcolumnas;
                end case ;
            end if;
        end if;

        
        if pb1 = '0' then -- boton para cambiar imagen
            delta2 := delta2 + 1;
            if delta2 = retraso then -- retraso para evitar rebote
                delta2 := 0; 
                if pb1 = '0' then -- lo acepta si continua presionado

                    grafico := grafico + 1;
                    if grafico = 7 then 
                        grafico := 0;
                    end if;
                    
                    memCol := 0;
                    memRow := 0;
                    conteoReloj := 0;
                    memOffset := memDirecciones(grafico, 0);
                    memFinal := memDirecciones(grafico, 1);
                    conteoMax := memFinal - memOffset;
                end if;
            end if;
        end if;

    end if;

end process salida_datos;

clk_out <= clk;
load_out <= load;
data_out <= salidaDato;

end Behavioral;
