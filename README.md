# LCD-energia.

En este repositorio se presenta la visualización de los datos obtenidos desde la base de datos. Inicialmente, se plantea mostrarlo en una pantalla LCD 16x2.

## Pantalla LCD

Se tiene que la pantalla LCD tiene los pines que se muestran a continuación: 
![](https://github.com/Scramos/LCD-energia/blob/master/Docs/lcdpines.png)

Los pines Vss y Vdd son tierra y alimentación respectivamente, V0 controla el contraste (puede que se llegue a necesitar un potenciometro), A y K son la alimentación para la retroiluminación, RS se usa para indicar si los datos en el bus con un caracter o una instrucción, E habilita la entrada de dato, R/W habilita o la lectura o la escritura en el dispositivo. Los ocho pines restantes son el bus de datos, que en este caso serán caracteres del código ASCII.

El controlador tiene un modo de 8 bits donde los caracteres y comandos se cargan un byte a la vez, y un modo de 4 bits donde los datos de 8 bits se cargan en dos paquetes de 4 bits.

## Funcionamiento

Inicialmente se plantea en el modulo una máquina de estados para generar los caracteres. Se utiliza un reloj de 100MHz que es el que tiene la tarjeta programable utilizada. 

Lo primero que se realiza es una inicialización para asegurarse de una recepción correcta del dato. Además, se debe tener en cuenta los retrazos que se generarn en cada ejecución de unsa instrucción. 

En este caso, se procesa los datos recibidos, que serán un bus de nueve datos (RS y DB0-7) por una maquina de estado de 26 pasos, de los cuales 23-25 se utilizan para la escritura en la LCD. Los otros son isntrucciones para realizar diferentes acciones, como enceder o apagar la pantalla, iniciar la entreda de datos o limpiar.

Se tendrá un dato de entrada dependiendo de lo que se entregue en la base de datos, también se tendrá un botón para la actualización de al base.
