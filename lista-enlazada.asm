.data
slist: 		.word 0  # Lista de nodos libres
cclist: 	.word 0  # Lista de categorías
wclist: 	.word 0  # Lista de trabajo (categoría actual)
schedv: 	.space 32  # Espacio para el vector de funciones del scheduler
menu: 		.ascii "Colecciones de objetos categorizados\n"
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
error: 		.asciiz "Error: "
return: 	.asciiz "\n"
catName: 	.asciiz "\nIngrese el nombre de una categoria: "
selCat: 	.asciiz "\nSe ha seleccionado la categoria:"
idObj: 		.asciiz "\nIngrese el ID del objeto a eliminar: "
objName: 	.asciiz "\nIngrese el nombre de un objeto: "
success: 	.asciiz "La operación se realizo con exito\n\n"

.text
main: 	
    la 		$t0, schedv  # Cargar la dirección del vector de funciones del scheduler en $t0
    la 		$t1, newcaterogy  # Cargar la dirección de la función newcaterogy en $t1
    sw 		$t1, 0($t0)  # Almacenar la dirección de newcaterogy en el vector de funciones
    la 		$t1, nextcategory  # Cargar la dirección de la función nextcategory en $t1
    sw 		$t1, 4($t0)  # Almacenar la dirección de nextcategory en el vector de funciones
    
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
    
newcaterogy:
    addiu	$sp, $sp, -4  # Reservar espacio en la pila
    sw 		$ra, 4($sp)  # Guardar el valor de $ra en la pila
    la 		$a0, catName  # Cargar la dirección del mensaje catName en $a0
    jal 	getblock  # Llamar a la subrutina getblock
    move 	$a2, $v0  # Mover la dirección del bloque asignado a $a2
    la 		$a0, cclist  # Cargar la dirección de la lista de categorías en $a0
    li 		$a1, 0  # Establecer $a1 en NULL
    jal 	addnode  # Llamar a la subrutina addnode
    lw 		$t0, wclist  # Cargar la dirección de la lista de trabajo en $t0
    bnez 	$t0, newcategory_end  # Si la lista de trabajo no está vacía, saltar a newcategory_end
    sw 		$v0, wclist  # Actualizar la lista de trabajo con la nueva categoría
newcategory_end:
    li 		$v0, 0  # Establecer $v0 en 0 (éxito)
    lw 		$ra, 4($sp)  # Restaurar el valor de $ra desde la pila
    addiu	$sp, $sp, 4  # Liberar espacio en la pila
    jr 		$ra  # Retornar de la subrutina
    # a0: list address
    # a1: NULL if category, node address if object
    # v0: node address added
nextcategory:
	
addnode:
    addi 	$sp, $sp, -8 # Reservar espacio en la pila
    sw 		$ra, 8($sp)  # Guardar el valor de $ra en la pila
    sw 		$a0, 4($sp)  # Guardar el valor de $a0 en la pila
    jal 	smalloc      # Llamar a la subrutina smalloc
    sw 		$a1, 4($v0)  # Establecer el contenido del nodo
    sw 		$a2, 8($v0)  # Establecer el nombre de la categoría en el nodo
    lw 		$a0, 4($sp)  # Restaurar el valor de $a0 desde la pila
    lw	 	$t0, ($a0)   # Cargar la dirección del primer nodo en $t0
    beqz 	$t0, addnode_empty_list  # Si la lista está vacía, saltar a addnode_empty_list

addnode_to_end:
    lw 		$t1, ($t0)  # Cargar la dirección del último nodo en $t1
    sw 		$t1, 0($v0)  # Establecer el puntero anterior del nuevo nodo
    sw 		$t0, 12($v0)  # Establecer el puntero siguiente del nuevo nodo
    sw	 	$v0, 12($t1)  # Actualizar el puntero siguiente del último nodo
    sw 		$v0, 0($t0)  # Actualizar el puntero anterior del primer nodo
    j 		addnode_exit  # Saltar a addnode_exit
    
addnode_empty_list:
    sw 		$v0, ($a0)  # Establecer el nuevo nodo como el primer nodo
    sw 		$v0, 0($v0)  # Establecer el puntero anterior del nuevo nodo
    sw 		$v0, 12($v0)  # Establecer el puntero siguiente del nuevo nodo

addnode_exit:
    lw 		$ra, 8($sp)  # Restaurar el valor de $ra desde la pila
    addi 	$sp, $sp, 8  # Liberar espacio en la pila
    jr 		$ra  # Retornar de la subrutina
    # a0: node address to delete
    # a1: list address where node is deleted
delnode:
    addi 	$sp, $sp, -8  # Reservar espacio en la pila
    sw 		$ra, 8($sp)  # Guardar el valor de $ra en la pila
    sw 		$a0, 4($sp)  # Guardar el valor de $a0 en la pila
    lw 		$a0, 8($a0)  # Cargar la dirección del bloque en $a0
    jal 	sfree  # Llamar a la subrutina sfree
    lw 		$a0, 4($sp)  # Restaurar el valor de $a0 desde la pila
    lw 		$t0, 12($a0)  # Cargar la dirección del siguiente nodo en $t0

node:
    beq 	$a0, $t0, delnode_point_self  # Si el nodo se apunta a sí mismo, saltar a delnode_point_self
    lw 		$t1, 0($a0)  # Cargar la dirección del nodo anterior en $t1
    sw 		$t1, 0($t0)  # Actualizar el puntero anterior del siguiente nodo
    sw 		$t0, 12($t1)  # Actualizar el puntero siguiente del nodo anterior
    lw 		$t1, 0($a1)  # Cargar la dirección del primer nodo en $t1

again:
    bne 	$a0, $t1, delnode_exit  # Si no es el primer nodo, saltar a delnode_exit
    sw 		$t0, ($a1)  # Actualizar el puntero de la lista al siguiente nodo
    j 	delnode_exit  # Saltar a delnode_exit

delnode_point_self:
    sw 		$zero, ($a1)  # Si es el único nodo, establecer la lista en NULL

delnode_exit:
    jal	sfree  # Llamar a la subrutina sfree
    lw		$ra, 8($sp)  # Restaurar el valor de $ra desde la pila
    addi	$sp, $sp, 8  # Liberar espacio en la pila
    jr		$ra  # Retornar de la subrutina
    # a0: msg to ask
    # v0: block address allocated with string

getblock:
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
    