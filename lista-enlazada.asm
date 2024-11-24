.data
menu: 			.ascii "Colecciones de objetos categorizados\n"
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
    la      $t1, add_object
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

    la      	$a0, successMsg
    li    	$v0, 4
    syscall
    
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

    la      	$a0, successMsg
    li    	$v0, 4
    syscall
    
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
    lw      $t0, cclist
    # 2. Verificar si la lista está vacía.
    beq     $t0, $zero, no_categories  # Si la lista está vacía, ir a no_categories

    # 4. Si la lista no está vacía, recorrer la lista y mostrar cada categoría.
    lw      $t1, wclist       
    move    $t2, $t0        # Inicializar el puntero de recorrido con el inicio de la lista

    # Guardar el primer nodo para detectar el ciclo
    move    $t3, $t0

show_loop:
    # 5. Marcar la categoría seleccionada con ">"
    beq     $t2, $t1, show_selected

    lw      $a0, 8($t2)  # Cargar el nombre de la categoría
    li      $v0, 4       # Código de syscall para imprimir cadena
    syscall
    
    # Mostrar nueva línea
    la      $a0, return
    li      $v0, 4
    syscall

    j       next_category

show_selected:
    # Mostrar el símbolo ">"
    li      $a0, '>'
    li      $v0, 11               # Código de syscall para imprimir carácter
    syscall
    
    lw      $a0, 8($t2)  # Cargar el nombre de la categoría
    li      $v0, 4       # Código de syscall para imprimir cadena
    syscall
    
    # Mostrar nueva línea
    la      $a0, return
    li      $v0, 4
    syscall

next_category:
    lw      $t2, 12($t2)  	# Cargar la dirección de la siguiente categoría en $t2
    beq     $t2, $t3, end_show  # Si hemos llegado al primer nodo, salir del ciclo
    j       show_loop       # Continuar al siguiente nodo

end_show:
    jr      $ra  # Retornar de la subrutina

no_categories:
    la      $a0, error            # Cargar el mensaje de error
    li      $v0, 4                # Código de syscall para imprimir cadena
    syscall

    li      $a0, 301              # Código de error 301
    li      $v0, 1                # Código de syscall para imprimir entero
    syscall
    
    # Mostrar nueva línea
    la      $a0, return
    li      $v0, 4
    syscall
    
    jr      $ra

delete_category:
    # Implementar la lógica para borrar categoría actual
    la      $a0, successMsg
    li      $v0, 4
    syscall
    jr      $ra

add_object:
    # Implementar la lógica para anexar objeto a la categoría actual
    la      $a0, successMsg
    li      $v0, 4
    syscall
    jr      $ra

show_objects:
    # Implementar la lógica para listar objetos de la categoría
    la      $a0, successMsg
    li      $v0, 4
    syscall
    jr      $ra

delete_object:
    # Implementar la lógica para borrar objeto de la categoría
    la      $a0, successMsg
    li      $v0, 4
    syscall
    jr      $ra

exit:
    # Salir del programa
    li      $v0, 10
    syscall
    
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
