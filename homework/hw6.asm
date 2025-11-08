; =============================================================================
; hw6.asm: Функція сортування (Бульбашка)
;
; Завдання: Написати функцію sort_array
; Вхід:
;   ESI - адреса масиву для сортування (оригінал)
;   EDI - адреса масиву для відсортованого масиву
;   ECX - кількість байтів для сортування (загальний розмір)
;   EBX - розмір одного елемента (1, 2, або 4 байти)
; =============================================================================

section .data
    ; --- Тестові дані ---
    ; Масив 32-бітних чисел (розмір елемента = 4)
    src_array dd 5, 2, 9, 1, 55, 12, 0, 8, 64, 33, 21, 13, 34, 3, 89, 144

    ; Розрахунок параметрів для sort_array
    ELEMENT_SIZE equ 4                     ; EBX: 4 байти (dd)
    ELEMENT_COUNT equ 16                    ; Кількість елементів
    TOTAL_BYTES equ ELEMENT_COUNT * ELEMENT_SIZE ; ECX: Загальний розмір

    ; Повідомлення
    msg_orig db "Оригінальний масив: "
    len_orig equ $ - msg_orig

    msg_sorted db "Відсортований масив: "
    len_sorted equ $ - msg_sorted

    msg_space db " ", 1
    len_space equ $ - msg_space

    newline db 0x0a
    len_newline equ $ - newline

section .bss
    ; Буфер для відсортованого масиву
    dest_array resb TOTAL_BYTES

    ; Буфер для int2str
    print_buffer resb 12

section .text
    global _start

; =============================================================================
; sort_array(ESI: src, EDI: dest, ECX: total_bytes, EBX: element_size)
; Сортує масив з ESI в EDI, використовуючи сортування бульбашками.
; =============================================================================
sort_array:
    pusha           ; Зберігаємо всі регістри

    ; --- 1. Розрахунок кількості елементів (n) ---
    push ecx        ; Зберігаємо total_bytes
    push ebx        ; Зберігаємо element_size

    mov eax, ecx    ; EAX = total_bytes
    xor edx, edx
    div ebx         ; EAX = total_bytes / element_size
    mov ecx, eax    ; ECX = n (кількість елементів)

    ; --- 2. Копіювання масиву з ESI в EDI ---
    pop ebx         ; Відновлюємо element_size
    pop eax         ; Відновлюємо total_bytes

    push edi        ; Зберігаємо початкову адресу EDI
    push ecx        ; Зберігаємо n (кількість елементів)

    mov ecx, eax    ; ECX = total_bytes
    cld             ; Очищуємо прапор напрямку (вперед)
    rep movsb       ; Копіюємо ECX байт з [ESI] в [EDI]

    pop ecx         ; Відновлюємо n (кількість елементів)
    pop edi         ; Відновлюємо початкову адресу EDI

    ; На цей момент:
    ; EDI - вказівник на початок масиву для сортування (dest_array)
    ; ECX - кількість елементів (n)
    ; EBX - розмір елемента (1, 2, 4)

    ; --- 3. Диспетчер сортування ---
    cmp ebx, 1
    je .sort_byte_impl
    cmp ebx, 2
    je .sort_word_impl
    cmp ebx, 4
    je .sort_dword_impl

    ; Якщо EBX != 1, 2, 4 (напр. 8, або невірний) - виходимо,
    ; залишаючи в EDI копію масиву
    jmp .sort_end

; --- Реалізація сортування бульбашками (4 байти, dword) ---
.sort_dword_impl:
    ; Зовнішній цикл: for (i = n-1; i > 0; i--)
    mov edx, ecx    ; EDX = i (зовнішній лічильник)
    dec edx         ; Починаємо з n-1
.outer_loop_dword:
    mov esi, edi    ; ESI = вказівник на 'j', починається з початку [EDI]
    xor ebp, ebp    ; EBP = j (внутрішній лічильник, від 0)
.inner_loop_dword:
    cmp ebp, edx    ; if (j >= i)
    jge .end_inner_dword

    mov eax, [esi]  ; eax = array[j]
    cmp eax, [esi + 4] ; порівняти з array[j+1] (розмір 4 байти)
    jle .no_swap_dword ; if (array[j] <= array[j+1])

    ; Міняємо місцями
    mov ebx, [esi + 4] ; ebx = array[j+1]
    mov [esi + 4], eax ; array[j+1] = array[j]
    mov [esi], ebx     ; array[j] = array[j+1]

.no_swap_dword:
    add esi, 4      ; рух вказівника 'j' на наступний елемент
    inc ebp         ; j++
    jmp .inner_loop_dword
.end_inner_dword:
    dec edx         ; i--
    jnz .outer_loop_dword ; Поки i != 0
    jmp .sort_end

; --- Реалізація сортування бульбашками (2 байти, word) ---
.sort_word_impl:
    mov edx, ecx
    dec edx
.outer_loop_word:
    mov esi, edi
    xor ebp, ebp
.inner_loop_word:
    cmp ebp, edx
    jge .end_inner_word

    mov ax, [esi]     ; Використовуємо 16-бітні регістри
    cmp ax, [esi + 2] ; Зсув на 2 байти
    jle .no_swap_word

    mov bx, [esi + 2]
    mov [esi + 2], ax
    mov [esi], bx

.no_swap_word:
    add esi, 2        ; Зсув на 2 байти
    inc ebp
    jmp .inner_loop_word
.end_inner_word:
    dec edx
    jnz .outer_loop_word
    jmp .sort_end

; --- Реалізація сортування бульбашками (1 байт, byte) ---
.sort_byte_impl:
    mov edx, ecx
    dec edx
.outer_loop_byte:
    mov esi, edi
    xor ebp, ebp
.inner_loop_byte:
    cmp ebp, edx
    jge .end_inner_byte

    mov al, [esi]     ; Використовуємо 8-бітні регістри
    cmp al, [esi + 1] ; Зсув на 1 байт
    jle .no_swap_byte

    mov bl, [esi + 1]
    mov [esi + 1], al
    mov [esi], bl

.no_swap_byte:
    add esi, 1        ; Зсув на 1 байт
    inc ebp
    jmp .inner_loop_byte
.end_inner_byte:
    dec edx
    jnz .outer_loop_byte

.sort_end:
    popa            ; Відновлюємо всі регістри
    ret

; =============================================================================
; _start: Головна функція
; =============================================================================
_start:
    ; --- 1. Виклик функції сортування ---
    mov esi, src_array
    mov edi, dest_array
    mov ecx, TOTAL_BYTES
    mov ebx, ELEMENT_SIZE
    call sort_array

    ; --- 2. Друк оригінального масиву ---
    mov ecx, msg_orig
    mov edx, len_orig
    call print

    mov esi, src_array      ; Адреса
    mov ecx, ELEMENT_COUNT  ; Кількість
    mov ebx, ELEMENT_SIZE   ; Розмір
    call print_array
    call print_newline

    ; --- 3. Друк відсортованого масиву ---
    mov ecx, msg_sorted
    mov edx, len_sorted
    call print

    mov esi, dest_array     ; Адреса
    mov ecx, ELEMENT_COUNT  ; Кількість
    mov ebx, ELEMENT_SIZE   ; Розмір
    call print_array
    call print_newline

    ; --- 4. Вихід ---
    call exit

; =============================================================================
; ДОПОМІЖНІ ФУНКЦІЇ
; =============================================================================

; -----------------------------------------------------------------------------
; print_array(ESI: address, ECX: count, EBX: element_size)
; Друкує масив на екран
; -----------------------------------------------------------------------------
print_array:
    pusha
.loop:
    cmp ecx, 0
    je .end

    ; Читаємо елемент
    xor eax, eax    ; Очищуємо EAX
    cmp ebx, 1
    je .read_byte
    cmp ebx, 2
    je .read_word
    ; Припускаємо, що це 4 байти (dword)
    mov eax, [esi]
    jmp .read_done
.read_word:
    mov ax, [esi]
    jmp .read_done
.read_byte:
    mov al, [esi]
.read_done:

    ; Друкуємо елемент
    push ecx        ; Зберігаємо лічильник
    push esi

    mov edi, print_buffer ; Використовуємо EDI для int2str
    call int2str_unsigned ; EAX -> рядок в [EDI]

    mov ecx, edi    ; Адреса рядка
    mov edx, eax    ; Довжина рядка
    call print

    ; Друк пробілу
    mov ecx, msg_space
    mov edx, len_space
    call print

    pop esi
    pop ecx

    ; Перехід до наступного елемента
    add esi, ebx    ; + element_size
    dec ecx         ; count--
    jmp .loop
.end:
    popa
    ret

; -----------------------------------------------------------------------------
; int2str_unsigned(EAX: number, EDI: buffer) -> EAX: length, EDI: addr
; Конвертує 32-бітне беззнакове число в рядок.
; Повертає довжину в EAX, вказівник на початок рядка в EDI.
; -----------------------------------------------------------------------------
int2str_unsigned:
    push ebx
    push ecx
    push edx

    mov ebx, 10
    add edi, 11     ; Переміщуємось в кінець буфера (10 цифр + \0)
    mov byte [edi], 0 ; Нуль-термінатор
    xor ecx, ecx    ; Лічильник довжини

.convert_loop:
    inc ecx
    xor edx, edx
    div ebx         ; EAX = EAX / 10, EDX = залишок
    add edx, '0'    ; Перетворюємо цифру в ASCII
    dec edi
    mov [edi], dl
    test eax, eax
    jnz .convert_loop

    mov eax, ecx    ; Повертаємо довжину в EAX

    pop edx
    pop ecx
    pop ebx
    ret

; -----------------------------------------------------------------------------
; print(ecx: address, edx: length)
; Друкує рядок на екран
; -----------------------------------------------------------------------------
print:
    pusha
    mov eax, 4
    mov ebx, 1
    int 0x80
    popa
    ret

; -----------------------------------------------------------------------------
; print_newline()
; Друкує символ нового рядка
; -----------------------------------------------------------------------------
print_newline:
    pusha
    mov ecx, newline
    mov edx, len_newline
    mov eax, 4
    mov ebx, 1
    int 0x80
    popa
    ret

; -----------------------------------------------------------------------------
; exit()
; Завершує програму
; -----------------------------------------------------------------------------
exit:
    mov eax, 1
    int 0x80
    ret