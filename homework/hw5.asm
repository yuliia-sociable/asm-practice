; =============================================================================
; hw5.asm: Виведення конверту в консоль ("діамантовий" тип)
;
; Вхід:
;   AH - ширина конверту (W)
;   AL - висота конверту (H)
;
; Валідація:
;   Програма перевіряє, що (W / H) є цілим числом > 0.
;   В іншому випадку виводиться помилка.
; =============================================================================

section .bss
    ; Глобальні змінні
    width       resd 1  ; W
    height      resd 1  ; H
    k_ratio     resd 1  ; k = W / H
    w_minus_1   resd 1  ; W - 1
    h_minus_1   resd 1  ; H - 1
    mid_y       resd 1  ; H / 2

    ; Координати діагоналей
    x_offset    resd 1
    x1          resd 1
    x2          resd 1

    ; Буфер для друку
    char_buffer resb 1

section .data
    newline     db 0x0a ; \n

    ; Повідомлення про помилку
    error_msg db "Помилка: (Ширина / Висота) не є цілим числом більше 0"
    len_error_msg equ $ - error_msg ; Автоматичний розрахунок довжини

section .text
    global _start

; -----------------------------------------------------------------------------
; _start: Головна функція програми
; -----------------------------------------------------------------------------
_start:
    ; --- 1. Налаштування вхідних даних (W і H) ---
    ; mov ah, 30 ; mov al, 15  (k=2, працює)
    ; mov ah, 32 ; mov al, 8   (k=4, працює)
    ; mov ah, 10 ; mov al, 20  (k=0, помилка)
    ; mov ah, 31 ; mov al, 15  (не ціле, помилка)
    mov ah, 30
    mov al, 15

    ; --- 2. Ініціалізація змінних ---
    movzx ebx, ah       ; EBX = Ширина (W)
    movzx ecx, al       ; ECX = Висота (H)
    mov [width], ebx
    mov [height], ecx

    ; --- 3. Валідація вхідних даних ---
    mov eax, [width]    ; EAX = W
    xor edx, edx        ; Обнуляємо EDX для ділення

    ; Перевірка на ділення на нуль
    cmp dword [height], 0
    je .handle_error

    div dword [height]  ; EAX = W / H (частка), EDX = W % H (залишок)

    ; Перевірка 1: Чи є залишок? (тобто чи ціле ділення)
    cmp edx, 0
    jne .handle_error   ; Якщо залишок (EDX) != 0, стрибаємо на помилку

    ; Перевірка 2: Чи частка = 0? (наприклад, 10 / 20 = 0)
    cmp eax, 0
    je .handle_error    ; Якщо частка (EAX) == 0, стрибаємо на помилку

    ; Якщо всі перевірки пройдені, зберігаємо k
    mov [k_ratio], eax

    ; --- 4. Продовження ініціалізації (якщо дані коректні) ---
    ; Зберігаємо W-1 та H-1
    mov ebx, [width]
    mov ecx, [height]
    dec ebx
    dec ecx
    mov [w_minus_1], ebx
    mov [h_minus_1], ecx

    ; Розраховуємо mid_y = H / 2
    mov eax, [height]
    shr eax, 1          ; Зсув вправо на 1 (ділення на 2)
    mov [mid_y], eax

    ; --- 5. Головний цикл (по рядках 'y') ---
    xor ebp, ebp        ; EBP = y (лічильник рядків)
.y_loop:
    mov ecx, [height]
    cmp ebp, ecx
    jge .y_loop_end     ; if (y >= H) break

    ; --- 6. Розрахунок 2-х діагональних точок для поточного 'y' ---
    mov eax, ebp
    cmp eax, [mid_y]
    jle .top_half

.bottom_half:
    ; y > mid_y, рахуємо "зворотний y"
    mov eax, [h_minus_1]
    sub eax, ebp

.top_half:
    ; EAX містить 'y' (для верхньої) або 'y_prime' (для нижньої)
    mul dword [k_ratio] ; x_offset = EAX * k
    mov [x1], eax       ; x1 = x_offset

    mov edx, [w_minus_1]
    sub edx, eax        ; x2 = (W-1) - x_offset
    mov [x2], edx

.x_loop_start:
    ; --- 7. Внутрішній цикл (по стовпцях 'x') ---
    xor edi, edi        ; EDI = x (лічильник стовпців)
.x_loop:
    mov ebx, [width]
    cmp edi, ebx
    jge .x_loop_end     ; if (x >= W) break

    ; --- 8. Визначення, який символ друкувати ---
    cmp ebp, 0
    je .print_star      ; Верхній кордон
    cmp ebp, [h_minus_1]
    je .print_star      ; Нижній кордон
    cmp edi, 0
    je .print_star      ; Лівий кордон
    cmp edi, [w_minus_1]
    je .print_star      ; Правий кордон

    mov eax, [x1]
    cmp edi, eax
    je .print_star      ; Діагональ 1

    mov eax, [x2]
    cmp edi, eax
    je .print_star      ; Діагональ 2

.print_space:
    mov al, ' '
    call print_char
    jmp .x_loop_next

.print_star:
    mov al, '*'
    call print_char

.x_loop_next:
    inc edi
    jmp .x_loop
.x_loop_end:

    call print_newline
    inc ebp
    jmp .y_loop
.y_loop_end:

    ; --- 9. Завершення програми (нормальне) ---
    call exit

; -----------------------------------------------------------------------------
; .handle_error: Секція обробки помилки
; -----------------------------------------------------------------------------
.handle_error:
    mov ecx, error_msg      ; Адреса повідомлення про помилку
    mov edx, len_error_msg  ; Довжина
    call print              ; Друк
    call print_newline
    call exit               ; Завершити програму

; =============================================================================
; ДОПОМІЖНІ ФУНКЦІЇ
; =============================================================================

; -----------------------------------------------------------------------------
; print(ecx: address, edx: length)
; Друкує цілий рядок
; -----------------------------------------------------------------------------
print:
    pusha
    mov eax, 4
    mov ebx, 1
    int 0x80
    popa
    ret

; -----------------------------------------------------------------------------
; print_char: Друкує 1 символ з AL
; -----------------------------------------------------------------------------
print_char:
    mov [char_buffer], al
    pusha
    mov eax, 4
    mov ebx, 1
    mov ecx, char_buffer
    mov edx, 1
    int 0x80
    popa
    ret

; -----------------------------------------------------------------------------
; print_newline: Друкує символ \n
; -----------------------------------------------------------------------------
print_newline:
    pusha
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    popa
    ret

; -----------------------------------------------------------------------------
; exit: Завершує програму
; -----------------------------------------------------------------------------
exit:
    mov eax, 1
    int 0x80
    ret