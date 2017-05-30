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
signal salidaArray : std_logic_vector(15 downto 0):=x"0B07";
signal dataOutCount : std_logic_vector(4 downto 0):="00000" ;
signal load     : std_logic := '1';
signal salidaDato : std_logic := '0';
type estados is (initcolumnas, encender, borrar, dibujar);
signal presente: estados;
signal datoEnviado : std_logic := '0';
-- signal grafico : std_logic_vector(3 downto 0) := (others => '0');
signal grafico : integer range 0 to 8;
signal cambiarGrafico : std_logic := '0';
signal cambioGrafico : std_logic := '0';

 type memIntegers5x2 is array (0 to 4, 0 to 1) of integer range 0 to 16;
 constant memDirecciones : memIntegers5x2 :=
 (
     (1,1),
     (2,2),
     (3,3),
     (5,5),
     (8,15)
 );

type mem16x8x8 is array (0 to 15, 0 to 7) of std_logic_vector(7 downto 0);
constant memoria_graficos : mem16x8x8 :=

(("00010000", "00110000", "00010000", "00010000", "00010000", "00010000", "00010000", "00111000"), -- digito 1
 ("00111000", "01000100", "00000100", "00000100", "00001000", "00010000", "00100000", "01111100"), -- digito 2
 ("00111000", "01000100", "00000100", "00011000", "00000100", "00000100", "01000100", "00111000"), -- digito 3
 (x"08",x"0C",x"FE",x"FF",x"FE",x"0C",x"08",x"00"), -- flecha izquierda (4)
 (x"38",x"38",x"38",x"38",x"FE",x"7C",x"38",x"10"), -- flecha derecha (5)
 (x"00",x"00",x"00",x"18",x"18",x"00",x"00",x"00"), -- cuadro centro (6)
 (x"00",x"00",x"3C",x"24",x"24",x"3C",x"00",x"00"), -- cuadro exterior (7)
 (x"44",x"82",x"82",x"82",x"82",x"82",x"82",x"82"), -- bateria 1 (8)
 (x"44",x"82",x"82",x"82",x"82",x"82",x"82",x"BA"),
 (x"44",x"82",x"82",x"82",x"82",x"BA",x"82",x"BA"),
 (x"44",x"82",x"82",x"BA",x"82",x"BA",x"82",x"BA"),
 (x"44",x"BA",x"82",x"BA",x"82",x"BA",x"82",x"BA"),
 (x"44",x"82",x"82",x"BA",x"82",x"BA",x"82",x"BA"),
 (x"44",x"82",x"82",x"82",x"82",x"BA",x"82",x"BA"),
 (x"44",x"82",x"82",x"82",x"82",x"82",x"82",x"BA"), -- bateria 8 final (15)
 (x"44",x"82",x"82",x"82",x"82",x"82",x"82",x"BA")); -- final (16)

begin

salida_datos : process( clk, pb1 )
    variable delta2 : integer range 0 to 1200;
    constant retraso : integer := 1200;
begin
    if rising_edge(clk) then
        if sw_reset = '1' then
            dataOutCount <= (others => '0');
            load <= '1';
            grafico <= 0;
        else
            if dataOutCount = "00000" then
                salidaArray <= dataArray;
            end if;

            dataOutCount <= dataOutCount + 1;
            if dataOutCount <= "01111" then
                salidaDato <= salidaArray(15);

                salidaArray <= salidaArray(14 downto 0) & salidaArray(15);
            end if;

            if dataOutCount >= "10000" then
                load <= '1';
            else
                load <= '0';
            end if;

            if dataOutCount = "11001" then -- 13 "10011" 25 "11001"
                dataOutCount <= (others => '0');
                datoEnviado <= '1';
            else
                datoEnviado <= '0';
            end if;
        end if;

        if pb1 = '0' then -- boton para cambiar imagen
            delta2 := delta2 + 1;
            if delta2 = retraso then -- retraso para evitar rebote
                delta2 := 0; 
                if pb1 = '0' then -- lo acepta si continua presionado
                    cambiarGrafico <= '1';
                    grafico <= grafico + 1;
                    if grafico = 5 then 
                        grafico <= 0;
                    end if;
                end if;
            end if;
        end if;

        if cambioGrafico = '1' then
            cambiarGrafico <= '0';
        end if;

    end if;

end process salida_datos;

logica_salidas : process( datoEnviado )
    variable memCol : integer range 0 to 8;
    variable memRow : integer range 0 to 21;
    variable conteoReloj : integer range 0 to 5000;
    variable delta : integer range 0 to 100;
    variable memOffset : integer range 0 to 16;
    variable memFinal : integer range 0 to 16;
begin

    if sw_reset = '1' then
        siguiente <= initcolumnas;
        memCol := 0;
        memRow := 0;
        conteoReloj := 0;
        delta := 0;
    elsif datoEnviado'event and datoEnviado = '1' then

        if cambiarGrafico = '1' then
            cambioGrafico <= '1';
            memCol := 0;
            memRow := 0;
            conteoReloj := 0;
        else
            cambioGrafico <= '0';
        end if;

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
 
                memOffset := memDirecciones(grafico, 0);
                memFinal := memDirecciones(grafico, 1);

                dataArray <= x"0" & CONV_STD_LOGIC_VECTOR(memCol + 1, 4) & memoria_graficos(memOffset + memRow, memCol);
                memCol := memCol + 1;

                if memCol = 8 then
                    memCol := 0;
                    conteoReloj := conteoReloj + 1;
                end if;

                -- 25*5=50
                if conteoReloj = 15 then -- espera un tiempo
                    conteoReloj := 0;
                    memRow := memRow + 1; -- avanza siguiente imagen en memoria
                    if memRow = memFinal then  -- termino de mostrar todas las imagenes
                        memRow := 0;    -- iniciar de nuevo desde la primera imagen
                    end if;
                end if ;

            when others =>
                presente <= initcolumnas;
        end case ;
       
    end if;
end process ; -- logica_salidas

clk_out <= clk;
load_out <= load;
data_out <= salidaDato;

end Behavioral;
