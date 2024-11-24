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
cclist: 		.word 0  # Lista de categorías
wclist: 		.word 0  # Lista de trabajo (categoría actual)
scheduler: 		.space 32  # Espacio para el vector de funciones del scheduler

.text
main: 	
    la      $t0, scheduler  # Cargar la dirección del vector de funciones del scheduler en $t0
    la      $t1, exit   # Cargar la dirección de la función newcategory en $t1
    sw      $t1, 0($t0)  # Almacenar la dirección de newcategory en el vector de funciones
    la      $t1, new_category 
    sw      $t1, 4($t0)  
    la      $t1, next_category 
    sw      $t1, 8($t0)
    la      $t1, previous_category
    sw      $t1, 12($t0)
    la      $t1, show_categories
    sw      $t1, 16($t0)
    la      $t1, delete_category
    sw      $t1, 20($t0)
    la      $t1, add_object
    sw      $t1, 24($t0)
    la      $t1, show_objects
    sw      $t1, 28($t0)
    la      $t1, delete_object 
    sw      $t1, 32($t0)
    
    j show_menu
    
show_menu:
    la      $a0, menu
    li      $v0, 4 # print menu
    syscall

    li      $v0, 5  # Leer entero
    syscall
    move    $t2, $v0  # Guardar la opción del usuario en $t2

    # Verificar si la opción es válida (0-8)
    blt     $t2, 0, invalid_option
    bgt     $t2, 8, invalid_option

    # Calcular la dirección de la función a llamar
    sll     $t2, $t2, 2  # Multiplicar la opción por 4 (tamaño de palabra)
    add     $t3, $t0, $t2  # Calcular la dirección de la función en el vector
    lw      $t4, 0($t3)  # Cargar la dirección de la función

    # Llamar a la función
    jalr    $t4

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
    sw 		$t0, slist  # Axctualizar la lista de nodos libres
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
new_category_end:
    li 		$v0, 0  # Establecer $v0 en 0 (éxito)
    lw 		$ra, 4($sp)  # Restaurar el valor de $ra desde la pila
    addiu	$sp, $sp, 4  # Liberar espacio en la pila
    jr 		$ra  # Retornar de la subrutina
    # a0: list address
    # a1: NULL if category, node address if object
    # v0: node address added
next_category:
    # Implementar la lógica para siguiente categoría
    la      $a0, successMsg
    li      $v0, 4
    syscall
    jr      $ra

previous_category:
    # Implementar la lógica para categoría anterior
    la      $a0, successMsg
    li      $v0, 4
    syscall
    jr      $ra

show_categories:
    # Implementar la lógica para listar categorías
    la      $a0, successMsg
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
    lw 		$t1, ($t0)  # Cargar la dirección del último nodo en $t1
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
    # a0: node address to delete
    # a1: list address where node is deleted
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
    
