PROGRAM Control_Tanques
  VAR_INPUT
    Paro_General : BOOL := FALSE;
    Modo_Operacion : BOOL := FALSE;
    Llenado_Manual_TG1 : BOOL := FALSE;
    Llenado_Manual_TG2 : BOOL := FALSE;
    Purga_Manual_TG1 : BOOL := FALSE;
    Purga_Manual_TG2 : BOOL := FALSE;
    Cambiar_Bomba_TE1 : BOOL := FALSE;
    Cambiar_Bomba_TE2 : BOOL := FALSE;
    Reset_Sistema : BOOL := FALSE;
  END_VAR
  VAR
    Nivel_TG1 AT %MD20 : REAL := 50.0;
    Nivel_TG2 AT %MD22 : REAL := 50.0;
  END_VAR
  VAR_INPUT
    Nivel_TE1 : REAL := 0.0;
    Nivel_TE2 : REAL := 0.0;
    Conductividad_TG1 : REAL := 500.0;
    Conductividad_TG2 : REAL := 500.0;
    Temperatura_TE1 : REAL := 0.0;
    Temperatura_TE2 : REAL := 0.0;
  END_VAR
  VAR
    EV_Llenado_TG1 AT %QX0.0 : BOOL := FALSE;
    EV_Llenado_TG2 AT %QX0.1 : BOOL := FALSE;
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
    Sensor_Nivel_Min_TG1 : BOOL := FALSE;
    Sensor_Nivel_Max_TG1 : BOOL := FALSE;
    Sensor_Nivel_Min_TG2 : BOOL := FALSE;
    Sensor_Nivel_Max_TG2 : BOOL := FALSE;
  END_VAR
  VAR
    Alarma_Temp_Alta_TE1 AT %MX100.0 : BOOL := FALSE;
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


  (* === PRUEBA DE COMUNICACIÓN MODBUS === *)
  (* Forzar valores para verificar que ScadaBR lee correctamente *)
  Nivel_TG1 := 75.5;  (* Valor de prueba *)
  Nivel_TG2 := 88.8;  (* Valor de prueba *)
  (* ===================================== *)

  (* === CONVERSIÓN REAL A INT PARA SCADABR === *)
  (* Multiplicamos por 10 y convertimos a INT *)
  (* En ScadaBR usaremos Multiplier: 0.1 para volver al valor real *)
  Nivel_Tg1int := REAL_TO_INT(Nivel_TG1 * 10.0);  (* 75.5 → 755 *)
  Nivel_Tg2int := REAL_TO_INT(Nivel_TG2 * 10.0);  (* 88.8 → 888 *)
  (* ========================================== *)

  IF Paro_General THEN

      (* --- Estado de seguridad --- *)

      EV_Llenado_TG1 := FALSE;

      EV_Llenado_TG2 := FALSE;

      V_Purga_TG1 := FALSE;

      V_Purga_TG2 := FALSE;

      Bomba_Principal_TE1 := FALSE;

      Bomba_Respaldo_TE1 := FALSE;

      Bomba_Principal_TE2 := FALSE;

      Bomba_Respaldo_TE2 := FALSE;



  ELSE

      (* ---- Simulación de llenado y vaciado de tanques ---- *)

      IF EV_Llenado_TG1 THEN

          Nivel_TG1 := Nivel_TG1 + 0.5;    (* Aumenta el nivel del tanque 1 *)

      ELSIF V_Purga_TG1 THEN

          Nivel_TG1 := Nivel_TG1 - 0.3;    (* Disminuye el nivel del tanque 1 *)

      END_IF;



      IF EV_Llenado_TG2 THEN

          Nivel_TG2 := Nivel_TG2 + 0.5;    (* Aumenta el nivel del tanque 2 *)

      ELSIF V_Purga_TG2 THEN

          Nivel_TG2 := Nivel_TG2 - 0.3;    (* Disminuye el nivel del tanque 2 *)

      END_IF;



      (* Limitar niveles a 0–100 *)

      IF Nivel_TG1 > 100.0 THEN Nivel_TG1 := 100.0; END_IF;

      IF Nivel_TG1 < 0.0 THEN Nivel_TG1 := 0.0; END_IF;

      IF Nivel_TG2 > 100.0 THEN Nivel_TG2 := 100.0; END_IF;

      IF Nivel_TG2 < 0.0 THEN Nivel_TG2 := 0.0; END_IF;

      
      (* Actualizar versiones INT para ScadaBR después de cambios *)
      Nivel_Tg1int := REAL_TO_INT(Nivel_TG1 * 10.0);
      Nivel_Tg2int := REAL_TO_INT(Nivel_TG2 * 10.0);


      (* ---- Control Tanque General 1 ---- *)

      IF Modo_Operacion = TRUE THEN

          IF Nivel_TG1 < 20.0 THEN

              EV_Llenado_TG1 := TRUE;

              Sensor_Nivel_Min_TG1 := TRUE;

          ELSIF Nivel_TG1 >= 95.0 THEN

              EV_Llenado_TG1 := FALSE;

              Sensor_Nivel_Max_TG1 := TRUE;

          ELSE

              Sensor_Nivel_Min_TG1 := FALSE;

              Sensor_Nivel_Max_TG1 := FALSE;

          END_IF;

      ELSE

          EV_Llenado_TG1 := Llenado_Manual_TG1;

      END_IF;



      IF (Conductividad_TG1 > 1000.0) OR (Purga_Manual_TG1 = TRUE) THEN

          V_Purga_TG1 := TRUE;

      ELSE

          V_Purga_TG1 := FALSE;

      END_IF;



      (* ---- Control Tanque General 2 ---- *)

      IF Modo_Operacion = TRUE THEN

          IF Nivel_TG2 < 20.0 THEN

              EV_Llenado_TG2 := TRUE;

              Sensor_Nivel_Min_TG2 := TRUE;

          ELSIF Nivel_TG2 >= 95.0 THEN

              EV_Llenado_TG2 := FALSE;

              Sensor_Nivel_Max_TG2 := TRUE;

          ELSE

              Sensor_Nivel_Min_TG2 := FALSE;

              Sensor_Nivel_Max_TG2 := FALSE;

          END_IF;

      ELSE

          EV_Llenado_TG2 := Llenado_Manual_TG2;

      END_IF;



      IF (Conductividad_TG2 > 1000.0) OR (Purga_Manual_TG2 = TRUE) THEN

          V_Purga_TG2 := TRUE;

      ELSE

          V_Purga_TG2 := FALSE;

      END_IF;



      (* ---- Control Bombas Tanque Elevado 1 ---- *)

      IF Cambiar_Bomba_TE1 = TRUE THEN

          IF Bomba_Activa_TE1 = 1 THEN

              Bomba_Activa_TE1 := 2;

          ELSE

              Bomba_Activa_TE1 := 1;

          END_IF;

          Cambiar_Bomba_TE1 := FALSE;

      END_IF;



      IF (Modo_Operacion = TRUE) AND (Nivel_TE1 > 20.0) THEN

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



      (* ---- Control Bombas Tanque Elevado 2 ---- *)

      IF Cambiar_Bomba_TE2 = TRUE THEN

          IF Bomba_Activa_TE2 = 1 THEN

              Bomba_Activa_TE2 := 2;

          ELSE

              Bomba_Activa_TE2 := 1;

          END_IF;

          Cambiar_Bomba_TE2 := FALSE;

      END_IF;



      IF (Modo_Operacion = TRUE) AND (Nivel_TE2 > 20.0) THEN

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



      (* ---- Alarmas ---- *)

      Alarma_Temp_Alta_TE1 := Temperatura_TE1 > 20.0;

      Alarma_Temp_Alta_TE2 := Temperatura_TE2 > 20.0;

      Alarma_Conductividad_Alta_TG1 := Conductividad_TG1 > 1000.0;

      Alarma_Conductividad_Alta_TG2 := Conductividad_TG2 > 1000.0;

      Alarma_Nivel_Bajo_TG1 := Nivel_TG1 < 20.0;

      Alarma_Nivel_Bajo_TG2 := Nivel_TG2 < 20.0;

      Alarma_Nivel_Bajo_TE1 := Nivel_TE1 < 20.0;

      Alarma_Nivel_Bajo_TE2 := Nivel_TE2 < 20.0;



      (* ---- Estados ---- *)

      IF (Alarma_Conductividad_Alta_TG1 OR Alarma_Nivel_Bajo_TG1) THEN

          Estado_TG1 := 2;

      ELSIF Conductividad_TG1 > 900.0 THEN

          Estado_TG1 := 1;

      ELSE

          Estado_TG1 := 0;

      END_IF;



      IF (Alarma_Conductividad_Alta_TG2 OR Alarma_Nivel_Bajo_TG2) THEN

          Estado_TG2 := 2;

      ELSIF Conductividad_TG2 > 900.0 THEN

          Estado_TG2 := 1;

      ELSE

          Estado_TG2 := 0;

      END_IF;



      IF (Alarma_Temp_Alta_TE1 OR Alarma_Nivel_Bajo_TE1) THEN

          Estado_TE1 := 2;

      ELSIF Temperatura_TE1 > 18.0 THEN

          Estado_TE1 := 1;

      ELSE

          Estado_TE1 := 0;

      END_IF;



      IF (Alarma_Temp_Alta_TE2 OR Alarma_Nivel_Bajo_TE2) THEN

          Estado_TE2 := 2;

      ELSIF Temperatura_TE2 > 18.0 THEN

          Estado_TE2 := 1;

      ELSE

          Estado_TE2 := 0;

      END_IF;



      (* ---- Contadores ---- *)

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

  END_IF;
END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK task0(INTERVAL := T#20ms,PRIORITY := 0);
    PROGRAM instance0 WITH task0 : Control_Tanques;
  END_RESOURCE
END_CONFIGURATION

(*DBG:char md5[] = "bbf3b37e5ae9033bfa2b04db0aac7e3c";*)
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
(*DBG:    {&(RES0__INSTANCE0.NIVEL_TE1), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.NIVEL_TE2), REAL_ENUM},*)
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