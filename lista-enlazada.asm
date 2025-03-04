.data
menu: 			.ascii "\nColecciones de objetos categorizados\n"
            		.ascii "====================================\n"
            		.ascii "1-Nueva categoria\n"
            		.ascii "2-Siguiente categoria\n"
            		.ascii "3-Categoria anterior\n"
            		.ascii "4-Listar categorias\n"
            		.ascii "5-Borrar categoria actual\n"
            		.ascii "6-Anexar objeto a la categoria actual\n"
            		.ascii "7-Listar objetos de la categoria\n"
 		        .ascii "8-Borrar objeto de la categoria\n"
			.ascii "0-Salir\n"
            		.asciiz "Ingrese la opcion deseada: "
            
error: 			.asciiz "Error: "
return: 		.asciiz "\n"
categoryNameMsg: 	.asciiz "\nIngrese el nombre de una categoria: "
selectedCategoryMsg:	.asciiz "\nSe ha seleccionado la categoria:"
objectIdMsg: 		.asciiz "\nIngrese el ID del objeto a eliminar: "
objectNameMsg: 		.asciiz "\nIngrese el nombre de un objeto: "
successMsg: 		.asciiz "La operación se realizo con exito\n\n"
msj_listar: 		.asciiz "\nEstos son los elementos de la lista:\n\n"
notFoundMsg:		.asciiz "\n NotFoundObject \n"

slist: 			.word 0  # Lista de nodos libres
cclist: 		.word 0  # puntero a lista de categorías
wclist: 		.word 0  # puntero a lista de trabajo (categoría actual)

scheduler: 		.space 32  # Espacio para el vector de funciones del scheduler

.text
main: 	
    la      $t7, scheduler  # Cargar la dirección del scheduler en $t0
    la      $t1, exit   # Cargar la dirección de la función exit en $t1
    sw      $t1, 0($t7)  # Almacenar la dirección de exit en el vector de funciones
    la      $t1, new_category 
    sw      $t1, 4($t7)  
    la      $t1, select_next_category 
    sw      $t1, 8($t7)
    la      $t1, select_previous_category
    sw      $t1, 12($t7)
    la      $t1, show_categories
    sw      $t1, 16($t7)
    la      $t1, delete_category
    sw      $t1, 20($t7)
    la      $t1, new_object
    sw      $t1, 24($t7)
    la      $t1, show_objects
    sw      $t1, 28($t7)
    la      $t1, delete_object 
    sw      $t1, 32($t7)
    
    j show_menu
    
show_menu:
    la      $a0, menu
    li      $v0, 4 		# print menu
    syscall

    li      $v0, 5  		# Leer entero
    syscall
    move    $t2, $v0 	 	# Guardar la opción del usuario en $t2

    # Verificar si la opción es válida (0-8)
    blt     $t2, 0, invalid_option
    bgt     $t2, 8, invalid_option

    # Calcular la dirección de la función a llamar
    sll     $t2, $t2, 2  	# Desplazar a la izquierda la opción 2 bits (equivale a multiplicar por 4)
    add     $t3, $t7, $t2  	# Calcular la dirección de la función en el vector
    lw      $t4, 0($t3)  	# Cargar la dirección de la función

    jalr    $t4			# Llamar a la función

    j       show_menu

invalid_option:
    la      $a0, error
    li      $v0, 4
    syscall
    li      $a0, 101
    li      $v0, 1
    syscall
    
    la      $a0, return
    li      $v0, 4
    syscall
    
    j       show_menu
            
smalloc:
    lw		$t0, slist  # Cargar la dirección del primer nodo libre en $t0
    beqz	$t0, sbrk  # Si no hay nodos libres, saltar a sbrk
    move 	$v0, $t0  # Mover la dirección del nodo libre a $v0
    lw 		$t0, 12($t0)  # Cargar la dirección del siguiente nodo libre en $t0
    sw 		$t0, slist  # Actualizar la lista de nodos libres
    jr 		$ra  # Retornar de la subrutina

sbrk:
    li		$a0, 16  # Tamaño del nodo (4 palabras)
    li 		$v0, 9  # Código de syscall para sbrk
    syscall  
    
    li      $t1, 0       # Cargar 0 en $t1 (NULL)
    sw      $t1, 4($v0)  # Inicializar el segundo word en 0
    
    jr 		$ra  # Retornar de la subrutina

sfree:
    lw		$t0, slist  # Cargar la dirección del primer nodo libre en $t0
    sw 		$t0, 12($a0)  # Almacenar la dirección del primer nodo libre en el nodo a liberar
    sw 		$a0, slist  # Actualizar la lista de nodos libres con el nodo liberado
    jr 		$ra  # Retornar de la subrutina
    
new_category:
    addiu	$sp, $sp, -4  # Reservar espacio en la pila
    sw 		$ra, 4($sp)  # Guardar el valor de $ra en la pila
    la 		$a0, categoryNameMsg  # Cargar la dirección del mensaje catName en $a0
    jal 	get_block  # Llamar a la subrutina getblock
    move 	$a2, $v0  # Mover la dirección del bloque asignado a $a2
    la 		$a0, cclist  # Cargar la dirección de la lista de categorías en $a0
    li 		$a1, 0  # Establecer $a1 en NULL
    jal 	add_node  # Llamar a la subrutina addnode
    sw		$0, 4($v0) #node->objetos = null
    lw 		$t0, wclist  # Cargar la dirección de la lista de trabajo en $t0
    bnez 	$t0, new_category_end  # Si la lista de trabajo no está vacía, saltar a newcategory_end
    sw 		$v0, wclist  # Actualizar la lista de trabajo con la nueva categoría
    sw 		$v0, cclist  # Establecer la nueva categoría como la primera en la lista
    
new_category_end:
    lw 		$ra, 4($sp)  # Restaurar el valor de $ra desde la pila
    addiu	$sp, $sp, 4  # Liberar espacio en la pila
    jr 		$ra  # Retornar de la subrutina
 
# pasar a la categoría siguiente
select_next_category:
    # Si no hay categorías, error 201	
    lw      	$t0, cclist
    beq     	$t0, $zero, error_select_no_categories

    # Si hay una sola categoría, error 202    
    # Si la dirección siguiente es igual a la categoria actual, poseo una única categoría.
    lw		$t1, wclist
    lw    	$t2, 12($t1)    
    beq	  	$t1, $t2, error_select_one_category 
    
    sw      	$t2, wclist

    move	$t3, $ra
    la      	$a0, successMsg
    jal		print_string
    
    lw      	$a0, 8($t2)
    jal		print_string
    
    move	$ra, $t3	
    jr      	$ra
    
# pasar a la categoría anterior
select_previous_category:
        # Si no hay categorías, error 201	
    lw      	$t0, cclist
    beq     	$t0, $zero, error_select_no_categories

    # Si hay una sola categoría, error 202 
    # Si la dirección del antecesor es igual a la categoria actual, poseo una única categoría.
    lw		$t1, wclist
    lw    	$t2, 0($t1)    
    beq	  	$t1, $t2, error_select_one_category 
    
    sw      	$t2, wclist

    move	$t3, $ra
    la      	$a0, successMsg
    jal		print_string
    
    lw      	$a0, 8($t2)
    jal		print_string
    
    move	$ra, $t3	
    jr      	$ra


error_select_no_categories:

    la      	$a0, error            	# Cargar el mensaje de error
    li      	$v0, 4                	# Código de syscall para imprimir cadena
    syscall

    li      	$a0, 201              	# Código de error 201
    li      	$v0, 1                	# Código de syscall para imprimir entero
    syscall
    
    la      	$a0, return
    li      	$v0, 4
    syscall
    
    jr      	$ra

error_select_one_category:
    la      	$a0, error            	# Cargar el mensaje de error
    li      	$v0, 4                	# Código de syscall para imprimir cadena
    syscall

    li		$a0, 202           	# Código de error 202
    li      	$v0, 1                	# Código de syscall para imprimir entero
    syscall
    
    # Mostrar nueva línea
    la      	$a0, return
    li      	$v0, 4
    syscall
    
    jr      	$ra
			

# 1. Cargar el puntero a la lista de categorías.
# 2. Verificar si la lista está vacía.
# 3. Si la lista está vacía, mostrar el mensaje de error.
# 4. Si la lista no está vacía, recorrer la lista y mostrar cada categoría.
# 5. Marcar la categoría seleccionada con ">".
show_categories:
    # 1. Cargar el puntero a la lista de categorías.
    lw      	$t0, cclist
    # 2. Verificar si la lista está vacía.
    beq     	$t0, $zero, no_categories  # Si la lista está vacía, ir a no_categories

    # 4. Si la lista no está vacía, recorrer la lista y mostrar cada categoría.
    lw      	$t1, wclist       
    move    	$t2, $t0        # Inicializar el puntero de recorrido con el inicio de la lista

    # Guardar el primer nodo para detectar el ciclo
    move    	$t3, $t0

show_loop:
    # 5. Marcar la categoría seleccionada con ">"
    beq     	$t2, $t1, show_selected

    lw      	$a0, 8($t2)  # Cargar el nombre de la categoría
    li      	$v0, 4       # Código de syscall para imprimir cadena
    syscall
    
    # Mostrar nueva línea
    la      	$a0, return
    li      	$v0, 4
    syscall

    j       	next_category

show_selected:
    # Mostrar el símbolo ">"
    li      	$a0, '>'
    li      	$v0, 11               # Código de syscall para imprimir carácter
    syscall
    
    lw      	$a0, 8($t2)  # Cargar el nombre de la categoría
    li      	$v0, 4       # Código de syscall para imprimir cadena
    syscall
    
    # Mostrar nueva línea
    la      	$a0, return
    li      	$v0, 4
    syscall

next_category:
    lw      	$t2, 12($t2)  	# Cargar la dirección de la siguiente categoría en $t2
    beq     	$t2, $t3, end_show  # Si hemos llegado al primer nodo, salir del ciclo
    j       	show_loop       # Continuar al siguiente nodo

end_show:
    jr      	$ra  # Retornar de la subrutina

no_categories:
    la      	$a0, error            # Cargar el mensaje de error
    li      	$v0, 4                # Código de syscall para imprimir cadena
    syscall

    li      	$a0, 301              # Código de error 301
    li      	$v0, 1                # Código de syscall para imprimir entero
    syscall
    
    # Mostrar nueva línea
    la      	$a0, return
    li      	$v0, 4
    syscall
    
    jr      	$ra

delete_category:
    addi        $sp, $sp, -8
    sw          $ra, 4($sp)
    sw          $s0, 0($sp)

    lw          $s0, wclist        # Nodo seleccionado en $s0
    lw          $s1, cclist        # Primer nodo de la lista en $s1

    beqz        $s1, _borrar_cat   # Si la lista está vacía, volver

    lw          $t0, 0($s0)        # $t0 = nodo->anterior
    lw          $t1, 12($s0)       # $t1 = nodo->siguiente

    # Caso 1: Nodo único en la lista
    beq         $s0, $t1, nodo_unico

    # Actualizar los punteros de los nodos adyacentes
    sw          $t0, 0($t1)        # $t1->anterior = $t0
    sw          $t1, 12($t0)       # $t0->siguiente = $t1

    # Si el nodo a borrar es el primero de la lista, actualizar cclist
    beq         $s0, $s1, actualizar_cclist

    # Si el nodo a borrar es el nodo seleccionado (wclist), actualizar wclist
    beq         $s0, $s0, actualizar_wclist

    j           liberar_nodo

# Caso 1: Nodo único en la lista
nodo_unico:
    sw          $zero, wclist
    sw          $zero, cclist
    j           liberar_nodo

# Actualizar el primer nodo de la lista (cclist)
actualizar_cclist:
    sw          $t1, cclist        # Nuevo primer nodo
    sw		$t1, wclist
    j           liberar_nodo

# Actualizar el nodo seleccionado (wclist)
actualizar_wclist:
    sw          $t1, wclist        # Nuevo nodo seleccionado
    j           liberar_nodo

# Liberar memoria del nodo y del string asociado
liberar_nodo:
    lw          $a0, 8($s0)
    jal         sfree               # Liberar memoria del string

    move        $a0, $s0
    jal         sfree               # Liberar memoria del nodo

_borrar_cat:
    lw          $s0, 0($sp)
    lw          $ra, 4($sp)
    addi        $sp, $sp, 8
    jr          $ra
new_object:
    # Guardar el registro de retorno
    addi    	$sp, $sp, -4
    sw      	$ra, 4($sp)

    # Comprobar si hay un nodo seleccionado
    lw      	$t0, wclist          # $t0 = nodo seleccionado
    beqz    	$t0, error_501       # Si no hay nodo seleccionado, ir a error

    # Obtener el nombre del objeto
    la      	$a0, objectNameMsg   # Mensaje para el nombre del objeto
    jal     	get_block            # Llamar a get_block
    move    	$s5, $v0             # $s5 = nombre del objeto

    # Asignar memoria para el nuevo nodo
    jal     	smalloc              # Llamar a smalloc
    move    	$s6, $v0             # $s6 = dirección del nuevo nodo
    sw      	$s5, 8($s6)          # Establecer el nombre en el nuevo nodo
    
    lw      	$t0, wclist
    lw      	$t1, 4($t0)          # $t1 = category->objects
    # Verificar si la lista está vacía
    beqz    	$t1, add_obj_empty_list

add_obj_to_end:
    # Agregar el nodo al final de la lista
    lw      	$t2, 0($t1)          # $t2 = último nodo de la lista
    sw      	$t2, 0($s6)          # nuevo->prev = último nodo
    sw      	$t1, 12($s6)         # nuevo->next = primer nodo
    sw      	$s6, 12($t2)         # último->next = nuevo
    sw      	$s6, 0($t1)          # primer->prev = nuevo

    # Asignar un ID incrementado al nuevo nodo
    lw      	$t3, 4($t2)          # $t7 = id del último nodo
    addi    	$t3, $t3, 1          # $t3 = nuevo id
    sw      	$t3, 4($s6)          # nuevo->id = $t4
    # Restaurar el registro de retorno y regresar
    la		$a0, successMsg
    jal		print_string
    j       	agregar_obj_return

add_obj_empty_list:
    # Si la lista está vacía, agregar el nodo como único elemento
    lw      	$t0, wclist		
    sw      	$s6, 4($t0)          # primer nodo de la lista
    sw      	$s6, 12($s6)         # nuevo->next = sí mismo
    sw      	$s6, 0($s6)          # nuevo->prev = sí mismo
    li      	$t2, 1               # ID inicial = 1
    sw      	$t2, 4($s6)          # nuevo->id = 1
        # Restaurar el registro de retorno y regresar
    la		$a0, successMsg
    jal		print_string
agregar_obj_return:
    lw      	$ra, 4($sp)
    addi    	$sp, $sp, 4
    jr      	$ra

error_501:
    # Imprimir mensaje de error y código 501
    la      $a0, error
    li      $v0, 4                # syscall para imprimir cadena
    syscall

    li      $a0, 501              # Código de error 501
    li      $v0, 1                # syscall para imprimir entero
    syscall

    j       agregar_obj_return


show_objects:
    addi    	$sp, $sp, -4
    sw      	$ra, 4($sp)
    
    lw		$t0, cclist
    beqz	$t0, error_601
    
    lw      	$t1, wclist        		# $t0 = nodo seleccionado
    beqz    	$t1, show_objects_exit   		# si no hay nodo seleccionado, volver al menu
    
    lw     	$s0, 4($t1)        		# $s0 = dir al primer nodo
    beqz    	$s0, error_602   	# si hay nodo seleccionado pero sin lista de objetos, volver al menu
    
    la      	$a0, msj_listar
    jal     	print_string
    move	$s1, $s0 # direccion inicial en s1
    
listar_obj_loop:
    lw      $a0, 4($s0)      # Carga el primer valor
    jal     print_int         # Imprime el entero

    li      $a0, '-'          # Imprime un guion
    jal     print_char

    lw      $a0, 8($s0)       # Carga la cadena
    jal     print_string       # Imprime la cadena

    lw      $t0, 12($s0)      # Carga el siguiente puntero
    beq     $t0, $s1, show_objects_exit # Si vuelve al inicio, salir
    move    $s0, $t0          # Avanza al siguiente nodo
    j       listar_obj_loop    # Repetir el bucle

    
error_601:
    la      	$a0, error            	# Cargar el mensaje de error
    li      	$v0, 4                	# Código de syscall para imprimir cadena
    syscall

    li		$a0, 601           	# Código de error 601
    li      	$v0, 1                	# Código de syscall para imprimir entero
    syscall
    j show_objects_exit
    
error_602:
    la      	$a0, error            	# Cargar el mensaje de error
    li      	$v0, 4                	# Código de syscall para imprimir cadena
    syscall

    li		$a0, 602        	# Código de error 602
    li      	$v0, 1                	# Código de syscall para imprimir entero
    syscall
        
show_objects_exit:
    lw      $ra, 4($sp)
    addi    $sp, $sp, 4
    
    jr       $ra
    
delete_object:
    addi    $sp, $sp, -4
    sw      $ra, 4($sp)
    
    lw      $s1, cclist          # Cargar la lista de objetos
    beqz    $s1, error_701        # Error si la lista es nula

    lw      $s2, wclist          # Nodo seleccionado
    beqz    $s2, delete_object_exit  # Si no hay nodo seleccionado, salir

    lw      $s0, 4($s2)          # Primer nodo de la lista de objetos
    beqz    $s0, delete_object_exit  # Si la lista de objetos está vacía, salir

    la      $a0, objectIdMsg     # Solicitar ID del objeto
    jal     print_string

    jal     read_word            # Leer el ID
    move    $t1, $v0

    move    $t0, $s0             # Inicializar el puntero al nodo actual

find_object_loop:
    lw      $t2, 4($t0)          # Cargar el ID del nodo actual
    beq     $t1, $t2, delete_found  # Si el ID coincide, ir a borrar

    lw      $t0, 12($t0)         # Siguiente nodo
    beq     $t0, $s0, object_not_found  # Si vuelve al inicio, no se encontró el objeto

    j       find_object_loop

delete_found:
    lw      	$t3, 0($t0)          # Nodo anterior
    lw      	$t4, 12($t0)         # Nodo siguiente

    sw      	$t3, 0($t4)          # Actualizar $t4->ant = $t3
    sw      	$t4, 12($t3)         # Actualizar $t3->sig = $t4
    
    move	$s3, $t0
    lw      	$a0, 8($s3)          # Liberar memoria del string
    jal     	sfree                
    la      	$a0, 4($s3)          # Liberar memoria del ID
    jal     	sfree                
    move    	$a0, $s3             # Liberar memoria del nodo
    jal     	sfree                

    # Si es el único nodo en la lista
    beq     	$t3, $t4, clear_selected_node
    # Si es el primer nodo de la lista
    beq     	$s0, $t0, update_first_node

    j       delete_object_exit

clear_selected_node:
    sw      $zero, 8($s2)        # nodo_seleccionado->objetos = NULL
    sw      $s2, wclist          # Actualizar wclist
    j       delete_object_exit

update_first_node:
    sw      $t4, 8($t3)          # Actualizar el primer nodo de la lista
    j       delete_object_exit

object_not_found:
    la      $a0, notFoundMsg     # Cargar el mensaje "NotFound"
    jal     print_string
    j       delete_object_exit

error_701:
    la      $a0, error           # Mostrar mensaje de error
    li      $v0, 4               
    syscall

    li      $a0, 701             # Código de error 701
    li      $v0, 1               
    syscall

delete_object_exit:
    lw      $ra, 4($sp)
    addi    $sp, $sp, 4
    jr      $ra    
print_string:
    # Asumimos que $a0 contiene la dirección de la cadena
    li      $v0, 4
    syscall
    jr      $ra
    
print_int:
    li			$v0, 1
    syscall
    jr			$ra
    
print_char:
    li			$v0, 11
    syscall
    jr			$ra
    
# READ_WORD
# lee un input numerico del usuario
read_word:
    li 		$v0, 5
    syscall
		
    jr		$ra

exit:
    # Salir del programa
    li      $v0, 10
    syscall

# a0: list address        
# a1: NULL if category, node address if object        
# v0: node address added
add_node:
    addi 	$sp, $sp, -8 # Reservar espacio en la pila
    sw 		$ra, 8($sp)  # Guardar el valor de $ra en la pila
    sw 		$a0, 4($sp)  # Guardar el valor de $a0 en la pila
    jal 	smalloc      # Llamar a la subrutina smalloc
    sw 		$a1, 4($v0)  # Establecer el contenido del nodo
    sw 		$a2, 8($v0)  # Establecer el nombre de la categoría en el nodo
    lw 		$a0, 4($sp)  # Restaurar el valor de $a0 desde la pila
    lw	 	$t0, ($a0)   # Cargar la dirección del primer nodo en $t0
    beqz 	$t0, add_node_empty_list  # Si la lista está vacía, saltar a addnode_empty_list
    
add_node_to_end:
    lw 		$t1, 12($t0)  # Cargar la dirección del último nodo en $t1
    sw 		$t1, 0($v0)  # Establecer el puntero anterior del nuevo nodo
    sw 		$t0, 12($v0)  # Establecer el puntero siguiente del nuevo nodo
    sw	 	$v0, 12($t1)  # Actualizar el puntero siguiente del último nodo
    sw 		$v0, 0($t0)  # Actualizar el puntero anterior del primer nodo
    j 		add_node_exit  # Saltar a addnode_exit
    
add_node_empty_list:
    sw 		$v0, ($a0)  # Establecer el nuevo nodo como el primer nodo
    sw 		$v0, 0($v0)  # Establecer el puntero anterior del nuevo nodo
    sw 		$v0, 12($v0)  # Establecer el puntero siguiente del nuevo nodo

add_node_exit:
    lw 		$ra, 8($sp)  # Restaurar el valor de $ra desde la pila
    addi 	$sp, $sp, 8  # Liberar espacio en la pila
    jr 		$ra  # Retornar de la subrutina

delete_node:
    addi 	$sp, $sp, -8  # Reservar espacio en la pila
    sw 		$ra, 8($sp)  # Guardar el valor de $ra en la pila
    sw 		$a0, 4($sp)  # Guardar el valor de $a0 en la pila
    lw 		$a0, 8($a0)  # Cargar la dirección del bloque en $a0
    jal 	sfree  # Llamar a la subrutina sfree
    lw 		$a0, 4($sp)  # Restaurar el valor de $a0 desde la pila
    lw 		$t0, 12($a0)  # Cargar la dirección del siguiente nodo en $t0

node:
    beq 	$a0, $t0, delete_node_point_self  # Si el nodo se apunta a sí mismo, saltar a delnode_point_self
    lw 		$t1, 0($a0)  # Cargar la dirección del nodo anterior en $t1
    sw 		$t1, 0($t0)  # Actualizar el puntero anterior del siguiente nodo
    sw 		$t0, 12($t1)  # Actualizar el puntero siguiente del nodo anterior
    lw 		$t1, 0($a1)  # Cargar la dirección del primer nodo en $t1

again:
    bne 	$a0, $t1, delete_node_exit  # Si no es el primer nodo, saltar a delnode_exit
    sw 		$t0, ($a1)  # Actualizar el puntero de la lista al siguiente nodo
    j 	delete_node_exit  # Saltar a delnode_exit

delete_node_point_self:
    sw 		$zero, ($a1)  # Si es el único nodo, establecer la lista en NULL

delete_node_exit:
    jal	sfree  # Llamar a la subrutina sfree
    lw		$ra, 8($sp)  # Restaurar el valor de $ra desde la pila
    addi	$sp, $sp, 8  # Liberar espacio en la pila
    jr		$ra  # Retornar de la subrutina

# a0: msg to ask        
# v0: block address allocated with string
get_block:
    addi	$sp, $sp, -4  # Reservar espacio en la pila
    sw		$ra, 4($sp)  # Guardar el valor de $ra en la pila
    li		$v0, 4  # Código de syscall para leer una cadena
    syscall  	
    jal		smalloc  # Llamar a la subrutina smalloc
    move	$a0, $v0  # Mover la dirección del bloque asignado a $a0
    li		$a1, 16  # Establecer el tamaño del bloque en 16
    li		$v0, 8  # Código de syscall para leer una cadena
    syscall
    move	$v0, $a0  # Mover la dirección del bloque asignado a $v0
    lw		$ra, 4($sp)  # Restaurar el valor de $ra desde la pila
    addi	$sp, $sp, 4  # Liberar espacio en la pila
    jr		$ra  # Retornar de la subrutina
