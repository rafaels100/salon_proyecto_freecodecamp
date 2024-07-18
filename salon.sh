#!/bin/bash
#coneccion al servidor
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"


#mensajes de bienvenida
echo -e "\n~~~~~ MY SALON ~~~~~"
echo -e "\nWelcome to my salon, how can I help you?\n"

#funcion main, se vuelve aca cada vez que sea necesario
function MAIN_MENU(){
  #si ingresa con algun argumento, muestro a pantalla el argumento como mensaje 
  if [[ $1 ]] 
  then
    echo -e $1
  fi
  query="
  SELECT * FROM services;
  "
  SERVICIOS=$($PSQL "$query")
  #echo "$SERVICIOS"
  echo "$SERVICIOS" | while IFS=" | " read ID SERVICIO
  do
    echo "$ID) $SERVICIO"
  done
  read SERVICE_ID_SELECTED
  SERVICE_ID=$($PSQL "SELECT service_id FROM services WHERE service_id='$SERVICE_ID_SELECTED'")
  if [[ -z $SERVICE_ID ]]
  then
    #si el servicio no se encontro
    MAIN_MENU "\nI could not find that service. What would you like today?"
  else
  	#sabiendo que ese service_id existe, obtengo el nombre. Lo limpio de espacios blancos que pueda tener al ppio o al final usando piping y sed, con el flag -E para
  	#habilitar expresiones regex
  	SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id='$SERVICE_ID'" | sed -E 's/^ *| *$//g')
  	#EXPLICACION del patron regex 's/^ *| *$//'
		#^ * => ^ indica que miro desde el primer caracter. Si el primer caracter es un espacio en blanco, y todos los caracteres que siguen * tambien lo son, los matcheo
		#| => o ocurre que
		# *$ => $indica el ultimo caracter. Si hay un espacio en blanco (o varios *) en el ultimo caracter, los matcheo
 		#Luego los reemplazo por nada, con el flag g para reemplazar cada match que aparece (como maximo va a haber 2 matchs, con blanks al ppio y al final)
    #el numero de telefono es unico de cada cliente. Es como un pseudo primary key, porque inicialmente no le puedo pedir al cliente su client_id, si es que tuviera
    #pero el numero de telefono es unico, como el DNI
    echo -e "\nWhat's your phone number?"
    read CUSTOMER_PHONE
    #Busco al cliente en la base de datos
    query="
    SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE';
    "
    CUSTOMER_ID=$($PSQL "$query")
    #chequeo si esta o no en la base de datos
    if [[ -z $CUSTOMER_ID ]]
    then
      #el cliente no esta en la base de datos. Debo agregarlo
      echo -e "\nI don't have a record for that phone number, what's your name?"
      read CUSTOMER_NAME
      #Inserto al cliente en la base de datos con su nombre y numero de telefono
      query="
      INSERT INTO customers(phone, name) VALUES ('$CUSTOMER_PHONE', '$CUSTOMER_NAME');
      "
      INSERTAR_CLIENTE=$($PSQL "$query")
      #echo $INSERTAR_CLIENTE
      if [[ $INSERTAR_CLIENTE == "INSERT 0 1" ]]
      then
      	#ahora que ingrese al cliente exitosamente, estoy seguro que se le asigno un customer_id. Lo busco y lo muestro a pantalla. Quito espacios en blanco
      	CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'" | sed -E 's/^ *| *$//g')
				#echo -e "\nEl cliente $CUSTOMER_NAME, con numero de telefono $CUSTOMER_PHONE, se registro correctamente y su numero de cliente es: $CUSTOMER_ID"
				
      else
      	MAIN_MENU "\nHubo un error al ingresar al cliente a la base de datos. Intentelo nuevamente."
      fi
    else
    	#si ocurre que si esta en la base de datos, busco su nombre 
    	CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id=$CUSTOMER_ID" | sed -E 's/^ *| *$//g')
    	#le doy la bienvenida nuevamente just for the laughs
    	#Por algun motivo el resultado viene rodeado de varios espacios en blanco. Puedo desacerme de ellos en un subshell usando sed
    	#Puedo deshacerme de los espacios en blanco en el propio echo, o al momento de crear la variable
    	#echo -e "\nBienvenido nuevamente $CUSTOMER_NAME, btw, su numero de cliente es $(echo $CUSTOMER_ID | sed -E 's/^ *| *$//g')"
    fi
    #Una vez salude al usuario que ya era habitue, o ingrese al nuevo cliente, debo registrar su cita
    #pregunto a que hora desea reservar su cita
    echo -e "\nWhat time would you like your cut, $CUSTOMER_NAME?"
    read SERVICE_TIME
    #Guardo el resultado en la tabla de citas
    query="
    INSERT INTO appointments(customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME');
    "
    REGISTRAR_CITA=$($PSQL "$query")
    #echo $REGISTRAR_CITA
    if [[ $REGISTRAR_CITA == "INSERT 0 1" ]] #0 errores 1 insercion
    then
    	echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $(echo $CUSTOMER_NAME | sed -E 's/^ *| *$//g')."
    else
    	MAIN_MENU "\nNo se pudo registrar la cita. Intentelo nuevamente."
    fi
  fi
}
MAIN_MENU