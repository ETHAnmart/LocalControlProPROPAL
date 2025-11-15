PROGRAM Control_Tanques
  VAR_INPUT
    Paro_General : BOOL := FALSE;
    Modo_Operacion : BOOL := FALSE;
    Llenado_Manual_TG1 : BOOL := FALSE;
    Llenado_Manual_TG2 : BOOL := FALSE;
  END_VAR
  VAR
    Purga_Manual_TG1 AT %MX12 : BOOL := FALSE;
    Purga_Manual_TG2 AT %MX13 : BOOL := FALSE;
  END_VAR
  VAR_INPUT
    Cambiar_Bomba_TE1 : BOOL := FALSE;
    Cambiar_Bomba_TE2 : BOOL := FALSE;
    Reset_Sistema : BOOL := FALSE;
  END_VAR
  VAR
    Nivel_TG1 AT %MD20 : REAL := 50.0;
    Nivel_TG2 AT %MD22 : REAL := 50.0;
    Nivel_TE1 AT %QW10 : INT := 24;
    Nivel_TE2 AT %QW11 : INT := 26;
  END_VAR
  VAR_INPUT
    Conductividad_TG1 : REAL := 500.0;
    Conductividad_TG2 : REAL := 500.0;
    Temperatura_TE1 : REAL := 0.0;
    Temperatura_TE2 : REAL := 0.0;
  END_VAR
  VAR
    EV_Llenado_TG1 : BOOL := FALSE;
    EV_Llenado_TG2 : BOOL := FALSE;
  END_VAR
  VAR_OUTPUT
    V_Purga_TG1 : BOOL := FALSE;
    V_Purga_TG2 : BOOL := FALSE;
    Bomba_Principal_TE1 : BOOL := FALSE;
    Bomba_Respaldo_TE1 : BOOL := FALSE;
    Bomba_Principal_TE2 : BOOL := FALSE;
    Bomba_Respaldo_TE2 : BOOL := FALSE;
  END_VAR
  VAR
    Sensor_Nivel_Min_TG1 AT %MX0.8 : BOOL := FALSE;
    Sensor_Nivel_Max_TG1 AT %MX0.9 : BOOL := FALSE;
    Sensor_Nivel_Min_TG2 AT %MX0.10 : BOOL := FALSE;
    Sensor_Nivel_Max_TG2 AT %MX0.11 : BOOL := FALSE;
    Alarma_Temp_Alta_TE1 AT %MX0.0 : BOOL := FALSE;
    Alarma_Temp_Alta_TE2 AT %MX0.1 : BOOL := FALSE;
    Alarma_Conductividad_Alta_TG1 AT %MX0.2 : BOOL := FALSE;
    Alarma_Conductividad_Alta_TG2 AT %MX0.3 : BOOL := FALSE;
    Alarma_Nivel_Bajo_TG1 AT %MX0.4 : BOOL := FALSE;
    Alarma_Nivel_Bajo_TG2 AT %MX0.5 : BOOL := FALSE;
    Alarma_Nivel_Bajo_TE1 AT %MX0.6 : BOOL := FALSE;
    Alarma_Nivel_Bajo_TE2 AT %MX0.7 : BOOL := FALSE;
    Estado_TG1 AT %QW0 : INT := 0;
    Estado_TG2 AT %QW1 : INT := 0;
    Estado_TE1 AT %QW2 : INT := 0;
    Estado_TE2 AT %QW3 : INT := 0;
    Fallas_Activas AT %QW4 : INT := 0;
    Bombas_Operativas AT %QW5 : INT := 0;
    Bomba_Activa_TE1 AT %QW6 : INT := 1;
    Bomba_Activa_TE2 AT %QW7 : INT := 1;
    Nivel_Tg1int AT %QW8 : INT := 0;
    Nivel_Tg2int AT %QW9 : INT := 0;
  END_VAR


  (* Este programa maneja la simulación, control y comunicación Modbus. *)
  (* Las variables Nivel_Tg1int y Nivel_Tg2int son las que ScadaBR debe leer. *)

  (* === INICIALIZACIÓN DE VALORES FIJOS (Solo se lee al inicio del ciclo) === *)
  (* NOTA: Si los valores Nivel_TG1 y Nivel_TG2 se inicializan en la tabla de variables, 
     las siguientes líneas se pueden comentar o eliminar. Si se dejan, fuerzan 
     los niveles a 75.5 y 88.8 en cada ciclo para propósito de pruebas. *)
  (* Nivel_TG1 := 75.5;  *)
  (* Nivel_TG2 := 88.8;  *)
  (* ======================================================================== *)


  IF Paro_General THEN

      (* --- Estado de seguridad (Todas las Salidas en FALSE) --- *)

      EV_Llenado_TG1 := FALSE;
      EV_Llenado_TG2 := FALSE;
      V_Purga_TG1 := FALSE;
      V_Purga_TG2 := FALSE;
      Bomba_Principal_TE1 := FALSE;
      Bomba_Respaldo_TE1 := FALSE;
      Bomba_Principal_TE2 := FALSE;
      Bomba_Respaldo_TE2 := FALSE;

      (* Las alarmas y contadores se limpian o mantienen según la lógica de seguridad,
         pero aquí se mantendrán hasta el bloque final de alarmas. *)


  ELSE (* === LÓGICA DE CONTROL OPERACIONAL === *)

      (* ---- Simulación de llenado y vaciado de tanques ---- *)

      (* La simulación se ejecuta ANTES que el control para que el control
         reaccione a los niveles actuales. *)

      IF EV_Llenado_TG1 THEN
          Nivel_TG1 := Nivel_TG1 + 0.5;   (* Aumenta el nivel del tanque 1 *)
      ELSIF V_Purga_TG1 THEN
          Nivel_TG1 := Nivel_TG1 - 0.3;   (* Disminuye el nivel del tanque 1 *)
      END_IF;

      IF EV_Llenado_TG2 THEN
          Nivel_TG2 := Nivel_TG2 + 0.5;   (* Aumenta el nivel del tanque 2 *)
      ELSIF V_Purga_TG2 THEN
          Nivel_TG2 := Nivel_TG2 - 0.3;   (* Disminuye el nivel del tanque 2 *)
      END_IF;

      (* Limitar niveles a 0–100 *)
      IF Nivel_TG1 > 100.0 THEN Nivel_TG1 := 100.0; END_IF;
      IF Nivel_TG1 < 0.0 THEN Nivel_TG1 := 0.0; END_IF;
      IF Nivel_TG2 > 100.0 THEN Nivel_TG2 := 100.0; END_IF;
      IF Nivel_TG2 < 0.0 THEN Nivel_TG2 := 0.0; END_IF;


      (* ---- Control Tanque General 1 ---- *)

      IF Modo_Operacion = TRUE THEN (* Modo Automático *)
          IF Nivel_TG1 < 20.0 THEN
              EV_Llenado_TG1 := TRUE;
          ELSIF Nivel_TG1 >= 95.0 THEN
              EV_Llenado_TG1 := FALSE;
          END_IF;
          (* La purga por conductividad no se ejecuta en este bloque, se ejecuta después *)
      ELSE (* Modo Manual *)
          EV_Llenado_TG1 := Llenado_Manual_TG1;
      END_IF;

      (* --- Control de Purga (Aplica a Automático y Manual) --- *)
      IF (Conductividad_TG1 > 1000.0) OR (Purga_Manual_TG1 = TRUE) THEN
          V_Purga_TG1 := TRUE;
      ELSE
          V_Purga_TG1 := FALSE;
      END_IF;


      (* ---- Control Tanque General 2 ---- *)

      IF Modo_Operacion = TRUE THEN (* Modo Automático *)
          IF Nivel_TG2 < 20.0 THEN
              EV_Llenado_TG2 := TRUE;
          ELSIF Nivel_TG2 >= 95.0 THEN
              EV_Llenado_TG2 := FALSE;
          END_IF;
      ELSE (* Modo Manual *)
          EV_Llenado_TG2 := Llenado_Manual_TG2;
      END_IF;

      (* --- Control de Purga (Aplica a Automático y Manual) --- *)
      IF (Conductividad_TG2 > 1000.0) OR (Purga_Manual_TG2 = TRUE) THEN
          V_Purga_TG2 := TRUE;
      ELSE
          V_Purga_TG2 := FALSE;
      END_IF;


      (* ---- Control Bombas Tanque Elevado 1 & 2 (Alternancia) ---- *)

      (* Alternancia de Bomba TE1 *)
      IF Cambiar_Bomba_TE1 = TRUE THEN
          IF Bomba_Activa_TE1 = 1 THEN
              Bomba_Activa_TE1 := 2;
          ELSE
              Bomba_Activa_TE1 := 1;
          END_IF;
          Cambiar_Bomba_TE1 := FALSE;
      END_IF;
      
      (* Alternancia de Bomba TE2 *)
      IF Cambiar_Bomba_TE2 = TRUE THEN
          IF Bomba_Activa_TE2 = 1 THEN
              Bomba_Activa_TE2 := 2;
          ELSE
              Bomba_Activa_TE2 := 1;
          END_IF;
          Cambiar_Bomba_TE2 := FALSE;
      END_IF;


      (* ---- Lógica de Encendido de Bombas ---- *)

      (* TE1 *)
      (* CORRECCIÓN DE ERROR: Nivel_TE1 es INT. Se convierte a REAL para la comparación con 20.0 *)
      IF (Modo_Operacion = TRUE) AND (INT_TO_REAL(Nivel_TE1) > 20.0) THEN
          IF Bomba_Activa_TE1 = 1 THEN
              Bomba_Principal_TE1 := TRUE;
              Bomba_Respaldo_TE1 := FALSE;
          ELSE
              Bomba_Principal_TE1 := FALSE;
              Bomba_Respaldo_TE1 := TRUE;
          END_IF;
      ELSE
          Bomba_Principal_TE1 := FALSE;
          Bomba_Respaldo_TE1 := FALSE;
      END_IF;

      (* TE2 *)
      (* CORRECCIÓN DE ERROR: Nivel_TE2 es INT. Se convierte a REAL para la comparación con 20.0 *)
      IF (Modo_Operacion = TRUE) AND (INT_TO_REAL(Nivel_TE2) > 20.0) THEN
          IF Bomba_Activa_TE2 = 1 THEN
              Bomba_Principal_TE2 := TRUE;
              Bomba_Respaldo_TE2 := FALSE;
          ELSE
              Bomba_Principal_TE2 := FALSE;
              Bomba_Respaldo_TE2 := TRUE;
          END_IF;
      ELSE
          Bomba_Principal_TE2 := FALSE;
          Bomba_Respaldo_TE2 := FALSE;
      END_IF;


      (* ---- Detección de Sensores de Nivel (Inputs) ---- *)
      (* NOTA: Estos se usan solo para ScadaBR y Alarmas. *)

      Sensor_Nivel_Min_TG1 := Nivel_TG1 <= 20.0;
      Sensor_Nivel_Max_TG1 := Nivel_TG1 >= 95.0;

      Sensor_Nivel_Min_TG2 := Nivel_TG2 <= 20.0;
      Sensor_Nivel_Max_TG2 := Nivel_TG2 >= 95.0;


      (* ---- Alarmas y Fallas ---- *)
      
      (* El error no está en Temperatura_TE1/2 ni Conductividad, ya que son REAL,
         pero mantenemos el formato REAL. *)
      Alarma_Temp_Alta_TE1 := Temperatura_TE1 > 20.0;
      Alarma_Temp_Alta_TE2 := Temperatura_TE2 > 20.0;
      Alarma_Conductividad_Alta_TG1 := Conductividad_TG1 > 1000.0;
      Alarma_Conductividad_Alta_TG2 := Conductividad_TG2 > 1000.0;
      
      (* La variable Nivel_TG1/2 es REAL, así que esta comparación está bien. *)
      Alarma_Nivel_Bajo_TG1 := Nivel_TG1 < 20.0;
      Alarma_Nivel_Bajo_TG2 := Nivel_TG2 < 20.0;
      
      (* CORRECCIÓN DE ERROR: Nivel_TE1 es INT. Se convierte a REAL para la comparación con 20.0 *)
      Alarma_Nivel_Bajo_TE1 := INT_TO_REAL(Nivel_TE1) < 20.0;
      
      (* CORRECCIÓN DE ERROR: Nivel_TE2 es INT. Se convierte a REAL para la comparación con 20.0 *)
      Alarma_Nivel_Bajo_TE2 := INT_TO_REAL(Nivel_TE2) < 20.0;


      (* ---- Actualización de Estados (0: Normal, 1: Advertencia, 2: Alarma) ---- *)
      
      (* Estado TG1 *)
      IF (Alarma_Conductividad_Alta_TG1 OR Alarma_Nivel_Bajo_TG1) THEN
          Estado_TG1 := 2; (* Alarma Crítica *)
      ELSIF Conductividad_TG1 > 900.0 THEN
          Estado_TG1 := 1; (* Advertencia *)
      ELSE
          Estado_TG1 := 0; (* Normal *)
      END_IF;

      (* Estado TG2 *)
      IF (Alarma_Conductividad_Alta_TG2 OR Alarma_Nivel_Bajo_TG2) THEN
          Estado_TG2 := 2; (* Alarma Crítica *)
      ELSIF Conductividad_TG2 > 900.0 THEN
          Estado_TG2 := 1; (* Advertencia *)
      ELSE
          Estado_TG2 := 0; (* Normal *)
      END_IF;

      (* Estado TE1 *)
      IF (Alarma_Temp_Alta_TE1 OR Alarma_Nivel_Bajo_TE1) THEN
          Estado_TE1 := 2; (* Alarma Crítica *)
      ELSIF Temperatura_TE1 > 18.0 THEN
          Estado_TE1 := 1; (* Advertencia *)
      ELSE
          Estado_TE1 := 0; (* Normal *)
      END_IF;

      (* Estado TE2 *)
      IF (Alarma_Temp_Alta_TE2 OR Alarma_Nivel_Bajo_TE2) THEN
          Estado_TE2 := 2; (* Alarma Crítica *)
      ELSIF Temperatura_TE2 > 18.0 THEN
          Estado_TE2 := 1; (* Advertencia *)
      ELSE
          Estado_TE2 := 0; (* Normal *)
      END_IF;


      (* ---- Contadores y Reset ---- *)

      Fallas_Activas := 0;
      IF Alarma_Temp_Alta_TE1 THEN Fallas_Activas := Fallas_Activas + 1; END_IF;
      IF Alarma_Temp_Alta_TE2 THEN Fallas_Activas := Fallas_Activas + 1; END_IF;
      IF Alarma_Conductividad_Alta_TG1 THEN Fallas_Activas := Fallas_Activas + 1; END_IF;
      IF Alarma_Conductividad_Alta_TG2 THEN Fallas_Activas := Fallas_Activas + 1; END_IF;

      Bombas_Operativas := 0;
      IF (Bomba_Principal_TE1 OR Bomba_Respaldo_TE1) THEN Bombas_Operativas := Bombas_Operativas + 1; END_IF;
      IF (Bomba_Principal_TE2 OR Bomba_Respaldo_TE2) THEN Bombas_Operativas := Bombas_Operativas + 1; END_IF;

      IF Reset_Sistema = TRUE THEN
          Fallas_Activas := 0;
          Reset_Sistema := FALSE;
      END_IF;

  END_IF; (* END IF Paro_General *)


  (* === CONVERSIÓN FINAL REAL A INT PARA SCADABR (Ejecutar siempre al final) === *)
  (* Esta sección es CRÍTICA para la comunicación con ScadaBR. *)
  (* Se ejecuta UNA SOLA vez al final para que Nivel_TgXint refleje el valor REAL actualizado. *)

  Nivel_Tg1int := REAL_TO_INT(Nivel_TG1 * 10.0);
  Nivel_Tg2int := REAL_TO_INT(Nivel_TG2 * 10.0);

  (* =========================================================================== *)
END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK task0(INTERVAL := T#20ms,PRIORITY := 0);
    PROGRAM instance0 WITH task0 : Control_Tanques;
  END_RESOURCE
END_CONFIGURATION

(*DBG:char md5[] = "ea50d7afa2d9ee5907ef1b50711217d6";*)
(*DBG:/**)
(*DBG: * This file is part of OpenPLC Runtime*)
(*DBG: **)
(*DBG: * Copyright (C) 2023 Autonomy, GP Orcullo*)
(*DBG: * Based on the work by GP Orcullo on Beremiz for uC*)
(*DBG: **)
(*DBG: * This program is free software; you can redistribute it and/or*)
(*DBG: * modify it under the terms of the GNU General Public License*)
(*DBG: * as published by the Free Software Foundation; either version 2*)
(*DBG: * of the License, or (at your option) any later version.*)
(*DBG: **)
(*DBG: * This program is distributed in the hope that it will be useful,*)
(*DBG: * but WITHOUT ANY WARRANTY; without even the implied warranty of*)
(*DBG: * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the*)
(*DBG: * GNU General Public License for more details.*)
(*DBG: **)
(*DBG: * You should have received a copy of the GNU General Public License*)
(*DBG: * along with this program; If not, see <http://www.gnu.org/licenses/>.*)
(*DBG: **)
(*DBG: */*)
(*DBG:*)
(*DBG:#include <stdbool.h>*)
(*DBG:*)
(*DBG:#include "iec_types_all.h"*)
(*DBG:#include "POUS.h"*)
(*DBG:*)
(*DBG:#define SAME_ENDIANNESS      0*)
(*DBG:#define REVERSE_ENDIANNESS   1*)
(*DBG:*)
(*DBG:uint8_t endianness;*)
(*DBG:*)
(*DBG:*)
(*DBG:extern CONTROL_TANQUES RES0__INSTANCE0;*)
(*DBG:*)
(*DBG:static const struct {*)
(*DBG:    void *ptr;*)
(*DBG:    __IEC_types_enum type;*)
(*DBG:} debug_vars[] = {*)
(*DBG:    {&(RES0__INSTANCE0.PARO_GENERAL), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.MODO_OPERACION), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.LLENADO_MANUAL_TG1), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.LLENADO_MANUAL_TG2), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PURGA_MANUAL_TG1), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PURGA_MANUAL_TG2), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.CAMBIAR_BOMBA_TE1), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.CAMBIAR_BOMBA_TE2), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.RESET_SISTEMA), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.NIVEL_TG1), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.NIVEL_TG2), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.NIVEL_TE1), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.NIVEL_TE2), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.CONDUCTIVIDAD_TG1), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.CONDUCTIVIDAD_TG2), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.TEMPERATURA_TE1), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.TEMPERATURA_TE2), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.EV_LLENADO_TG1), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.EV_LLENADO_TG2), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.V_PURGA_TG1), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.V_PURGA_TG2), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.BOMBA_PRINCIPAL_TE1), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.BOMBA_RESPALDO_TE1), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.BOMBA_PRINCIPAL_TE2), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.BOMBA_RESPALDO_TE2), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.SENSOR_NIVEL_MIN_TG1), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.SENSOR_NIVEL_MAX_TG1), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.SENSOR_NIVEL_MIN_TG2), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.SENSOR_NIVEL_MAX_TG2), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.ALARMA_TEMP_ALTA_TE1), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.ALARMA_TEMP_ALTA_TE2), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.ALARMA_CONDUCTIVIDAD_ALTA_TG1), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.ALARMA_CONDUCTIVIDAD_ALTA_TG2), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.ALARMA_NIVEL_BAJO_TG1), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.ALARMA_NIVEL_BAJO_TG2), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.ALARMA_NIVEL_BAJO_TE1), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.ALARMA_NIVEL_BAJO_TE2), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.ESTADO_TG1), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.ESTADO_TG2), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.ESTADO_TE1), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.ESTADO_TE2), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FALLAS_ACTIVAS), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.BOMBAS_OPERATIVAS), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.BOMBA_ACTIVA_TE1), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.BOMBA_ACTIVA_TE2), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.NIVEL_TG1INT), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.NIVEL_TG2INT), INT_ENUM},*)
(*DBG:};*)
(*DBG:*)
(*DBG:#define VAR_COUNT               47*)
(*DBG:*)
(*DBG:uint16_t get_var_count(void)*)
(*DBG:{*)
(*DBG:    return VAR_COUNT;*)
(*DBG:}*)
(*DBG:*)
(*DBG:size_t get_var_size(size_t idx)*)
(*DBG:{*)
(*DBG:    if (idx >= VAR_COUNT)*)
(*DBG:    {*)
(*DBG:        return 0;*)
(*DBG:    }*)
(*DBG:    switch (debug_vars[idx].type) {*)
(*DBG:    case REAL_ENUM:*)
(*DBG:        return sizeof(REAL);*)
(*DBG:    case INT_ENUM:*)
(*DBG:        return sizeof(INT);*)
(*DBG:    case BOOL_ENUM:*)
(*DBG:        return sizeof(BOOL);*)
(*DBG:    default:*)
(*DBG:        return 0;*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void *get_var_addr(size_t idx)*)
(*DBG:{*)
(*DBG:    void *ptr = debug_vars[idx].ptr;*)
(*DBG:*)
(*DBG:    switch (debug_vars[idx].type) {*)
(*DBG:    case REAL_ENUM:*)
(*DBG:        return (void *)&((__IEC_REAL_t *) ptr)->value;*)
(*DBG:    case INT_ENUM:*)
(*DBG:        return (void *)&((__IEC_INT_t *) ptr)->value;*)
(*DBG:    case BOOL_ENUM:*)
(*DBG:        return (void *)&((__IEC_BOOL_t *) ptr)->value;*)
(*DBG:    default:*)
(*DBG:        return 0;*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void force_var(size_t idx, bool forced, void *val)*)
(*DBG:{*)
(*DBG:    void *ptr = debug_vars[idx].ptr;*)
(*DBG:*)
(*DBG:    if (forced) {*)
(*DBG:        size_t var_size = get_var_size(idx);*)
(*DBG:        switch (debug_vars[idx].type) {*)
(*DBG:        case REAL_ENUM: {*)
(*DBG:            memcpy(&((__IEC_REAL_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_REAL_t *) ptr)->value = *((REAL *) val);*)
(*DBG:            ((__IEC_REAL_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case INT_ENUM: {*)
(*DBG:            memcpy(&((__IEC_INT_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_INT_t *) ptr)->value = *((INT *) val);*)
(*DBG:            ((__IEC_INT_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case BOOL_ENUM: {*)
(*DBG:            memcpy(&((__IEC_BOOL_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_BOOL_t *) ptr)->value = *((BOOL *) val);*)
(*DBG:            ((__IEC_BOOL_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        default:*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:    } else {*)
(*DBG:        switch (debug_vars[idx].type) {*)
(*DBG:        case REAL_ENUM:*)
(*DBG:            ((__IEC_REAL_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case INT_ENUM:*)
(*DBG:            ((__IEC_INT_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case BOOL_ENUM:*)
(*DBG:            ((__IEC_BOOL_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        default:*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void swap_bytes(void *ptr, size_t size) *)
(*DBG:{*)
(*DBG:    uint8_t *bytePtr = (uint8_t *)ptr;*)
(*DBG:    size_t i;*)
(*DBG:    for (i = 0; i < size / 2; ++i) *)
(*DBG:    {*)
(*DBG:        uint8_t temp = bytePtr[i];*)
(*DBG:        bytePtr[i] = bytePtr[size - 1 - i];*)
(*DBG:        bytePtr[size - 1 - i] = temp;*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void trace_reset(void)*)
(*DBG:{*)
(*DBG:    for (size_t i=0; i < VAR_COUNT; i++) *)
(*DBG:    {*)
(*DBG:        force_var(i, false, 0);*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void set_trace(size_t idx, bool forced, void *val)*)
(*DBG:{*)
(*DBG:    if (idx >= 0 && idx < VAR_COUNT) *)
(*DBG:    {*)
(*DBG:        if (endianness == REVERSE_ENDIANNESS)*)
(*DBG:        {*)
(*DBG:            // Aaaaarghhhh... Stupid AVR is Big Endian.*)
(*DBG:            swap_bytes(val, get_var_size(idx));*)
(*DBG:        }*)
(*DBG:*)
(*DBG:        force_var(idx, forced, val);*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void set_endianness(uint8_t value)*)
(*DBG:{*)
(*DBG:    if (value == SAME_ENDIANNESS || value == REVERSE_ENDIANNESS)*)
(*DBG:    {*)
(*DBG:        endianness = value;*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)