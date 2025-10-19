; =============================================================================
; hw41.asm: Ітеративний розрахунок факторіалу
;
; Обмеження:
; Вхідне число 'n' не може перевищувати 12.
; Результат 12! (479,001,600) вміщується в 32 біти (DX:AX).
; Результат 13! (6,227,020,800) вже не вміщується в 32 біти
; (макс. 4,294,967,295), тому програма виводить помилку.
; =============================================================================

section .bss
    input_buffer resb 12  ; Буфер для вхідного числа (n)
    result_buffer resb 12 ; Буфер для результату (n!)

section .data
    input_msg db "Вхідне число (n): ", 19
    len_input_msg equ $ - input_msg

    result_msg db "Факторіал (n!): ", 17
    len_result_msg equ $ - result_msg

    ; Повідомлення про помилку
    error_msg db "Помилка: n > 12. Результат не вміститься в DX:AX.", 53
    len_error_msg equ $ - error_msg

    newline db 0x0a, 1
    len_newline equ $ - newline

section .text
    global _start

; -----------------------------------------------------------------------------
; factorial_iterative(eax: n) -> eax: n!
; Ітеративно рахує факторіал.
; -----------------------------------------------------------------------------
factorial_iterative:
    mov ecx, eax        ; ecx = n (лічильник)
    mov eax, 1          ; eax = 1 (початковий результат)

    cmp ecx, 1          ; Перевірка на n=0 або n=1
    jle .end_factorial  ; Якщо n <= 1, повернути 1

.loop:
    ; 32-бітне множення: EAX = EAX * ECX.
    ; Результат зберігається в парі EDX:EAX.
    mul ecx

    dec ecx             ; ecx--
    cmp ecx, 1          ; Поки ecx > 1
    jg .loop

.end_factorial:
    ret

; -----------------------------------------------------------------------------
; _start: Головна функція програми
; -----------------------------------------------------------------------------
_start:
    ; --- Вхідне число ---
    mov ax, 5           ; <--- ВХІДНЕ ЧИСЛО (n). ЗМІНІТЬ ЙОГО ТУТ ---
    movzx eax, ax       ; Розширюємо AX до EAX (32-біт)

    ; Перевірка на переповнення
    cmp eax, 12
    jg .handle_overflow ; Якщо n > 12, перейти до секції помилки

    ; --- Якщо n <= 12, виконуємо стандартний код ---
    push eax            ; Зберігаємо 'n' в стеку

    ; --- Друк вхідного числа ---
    mov ecx, input_msg
    mov edx, len_input_msg
    call print          ; Друк "Вхідне число (n): "

    mov esi, input_buffer
    call int2str        ; Конвертуємо 'n' (з EAX) в рядок

    mov ecx, input_buffer
    mov edx, eax        ; EAX містить довжину рядка з int2str
    call print
    call print_newline

    ; --- Розрахунок факторіалу ---
    pop eax             ; Відновлюємо 'n' з стеку в EAX
    call factorial_iterative ; Рахуємо факторіал, результат в EAX

    ; --- Виконання вимоги DX:AX ---
    mov edx, eax        ; Копіюємо EAX (результат) в EDX
    shr edx, 16         ; Зсуваємо EDX на 16 біт вправо. Тепер DX = старші 16 біт
                        ; Молодші 16 біт вже знаходяться в AX

    ; --- Друк результату (n!) ---
    mov ecx, result_msg
    mov edx, len_result_msg
    call print          ; Друк "Факторіал (n!): "

    mov esi, result_buffer
    call int2str        ; Конвертуємо 'n!' (з EAX) в рядок

    mov ecx, result_buffer
    mov edx, eax
    call print
    call print_newline

    ; --- Вихід з програми ---
    call exit
    ; ---------------------------------------------------


; Секція обробки помилки
.handle_overflow:
    mov ecx, error_msg      ; Адреса повідомлення про помилку
    mov edx, len_error_msg  ; Довжина повідомлення
    call print              ; Друк помилки
    call print_newline
    call exit               ; Завершити програму


; -----------------------------------------------------------------------------
; print(ecx: address, edx: length)
; Друкує рядок на екран
; -----------------------------------------------------------------------------
print:
    pusha               ; Зберігаємо всі регістри
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    int 0x80            ; Виклик ядра
    popa                ; Відновлюємо регістри
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
    mov eax, 1          ; sys_exit
    int 0x80
    ret

; -----------------------------------------------------------------------------
; int2str(eax: number, esi: buffer) -> eax: length
; Конвертує 32-бітне число в рядок
; -----------------------------------------------------------------------------
int2str:
    push ebx
    push ecx
    push edx

    mov ebx, 10         ; Дільник 10
    xor ecx, ecx        ; Лічильник символів

.conversion_loop:
    xor edx, edx
    div ebx             ; Ділимо EAX на 10. EDX:EAX / EBX
    add edx, '0'        ; Перетворюємо залишок (EDX) в ASCII
    push edx            ; Зберігаємо в стеку
    inc ecx             ; ecx = довжина
    test eax, eax
    jnz .conversion_loop

    mov eax, ecx        ; Повертаємо довжину в EAX

.store_loop:
    pop edx             ; Дістаємо символ
    mov [esi], dl       ; Записуємо в буфер
    inc esi
    loop .store_loop

    pop edx
    pop ecx
    pop ebx
    ret