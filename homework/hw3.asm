section .data
    ; Повідомлення для виводу
    msg_prime       db ' is a prime number', 0x0a  ; '\n' в кінці
    len_prime       equ $ - msg_prime

    msg_not_prime   db ' is NOT a prime number', 0x0a ; '\n' в кінці
    len_not_prime   equ $ - msg_not_prime

    msg_one_or_zero db '1 or 0 is NOT a prime number', 0x0a
    len_one_or_zero equ $ - msg_one_or_zero

section .bss
    ; Буфер для зберігання результату конвертації числа
    ; 11 байт достатньо для 16-бітного числа (5 цифр) + \n
    ; Використовуємо 8 байт для запасу
    buffer resb 8

section .text
    global _start

; =============================================================================
; int2str_16bit(eax: integer, esi: buffer) -> eax: length
; Конвертує 16-бітне ціле число в рядок.
; Вхід:
;   AX - число для конвертації
;   ESI - вказівник на буфер для запису рядка
; Вихід:
;   EAX - довжина отриманого рядка
;   (Збережено регістри EBX, ECX, EDX)
; =============================================================================
int2str_16bit:
    push ebx
    push ecx
    push edx
    push eax            ; Зберігаємо AX (число)

    mov ebx, 10         ; Дільник 10
    xor ecx, ecx        ; Лічильник символів (довжина)

    ; Переміщуємо число з AX до EAX для використання DIV
    pop eax             ; Відновлюємо число в EAX
    xor edx, edx        ; Обнуляємо EDX

.conversion_loop:
    xor edx, edx        ; Обнуляємо EDX для DIV (EAX:EDX / EBX)
    div ebx             ; EAX = EAX/10, EDX = EAX % 10
    add edx, '0'        ; Перетворюємо залишок (цифру) в ASCII
    push edx            ; Зберігаємо символ у стеку
    inc ecx
    test eax, eax       ; Перевіряємо, чи EAX не нуль
    jnz .conversion_loop

    mov eax, ecx        ; Зберігаємо довжину рядка в EAX

.store_loop:
    pop edx             ; Дістаємо символ зі стека
    mov [esi], dl       ; Записуємо символ у буфер
    inc esi
    loop .store_loop    ; Повторюємо, поки ECX не стане 0

    ; !!! Не додаємо \n тут, щоб можна було додати повідомлення відразу після числа
    ; mov byte [esi], 0x0a ; \n
    ; inc eax              ; Збільшуємо довжину на 1

    pop edx
    pop ecx
    pop ebx
    ret

; =============================================================================
; Функція виводу рядка (ESI: адреса, EDX: довжина)
; =============================================================================
print_string:
    push eax
    push ebx
    push ecx

    mov ecx, esi        ; Адреса рядка
    mov ebx, 1          ; Файловий дескриптор: 1 = stdout
    mov eax, 4          ; Системний виклик: 4 = sys_write
    int 0x80            ; Викликаємо ядро

    pop ecx
    pop ebx
    pop eax
    ret

; =============================================================================
; Головна точка входу в програму
; =============================================================================
_start:
    mov ax, 13          ; <<< НАШЕ ЧИСЛО ДЛЯ ПЕРЕВІРКИ. ЗМІНИ ТУТ >>>

    ; -------------------------------------------------------------------------
    ; 1. Виводимо число на екран
    ; -------------------------------------------------------------------------
    push ax             ; Зберігаємо оригінальне число
    mov esi, buffer
    call int2str_16bit  ; EAX повертає довжину числа
    mov edx, eax        ; EDX = довжина числа
    mov esi, buffer     ; ESI = адреса буфера
    call print_string

    pop ax              ; Відновлюємо число в AX

    ; -------------------------------------------------------------------------
    ; 2. Перевірка на 0 або 1
    ; -------------------------------------------------------------------------
    cmp ax, 2
    jl .is_not_prime_one_or_zero ; Якщо AX < 2 (тобто 0 або 1), то не просте

    ; -------------------------------------------------------------------------
    ; 3. Перевірка на простоту
    ; -------------------------------------------------------------------------
    mov cx, ax          ; CX = число (N)
    mov bx, 2           ; BX = дільник (D), починаємо з 2

.check_loop:
    cmp bx, cx          ; Порівнюємо дільник (D) з числом (N).
    jge .is_prime       ; Якщо D >= N, то число просте (перевірили до N-1)

    ; Тут ми ділимо N на D
    xor dx, dx          ; Обнуляємо DX (пара DX:AX для ділення)
    mov ax, cx          ; AX = N (число)
    div bx              ; AX = N/D, DX = N % D

    cmp dx, 0           ; Перевіряємо залишок
    je .is_not_prime    ; Якщо залишок 0, то число ділиться, отже, не просте

    inc bx              ; Збільшуємо дільник
    mov ax, cx          ; Відновлюємо N в AX для наступної ітерації (оскільки DIV змінив AX)
    jmp .check_loop

    ; --- Результати ---
.is_not_prime:
    mov esi, msg_not_prime
    mov edx, len_not_prime
    jmp .print_result

.is_prime:
    mov esi, msg_prime
    mov edx, len_prime
    jmp .print_result

.is_not_prime_one_or_zero:
    mov esi, msg_one_or_zero
    mov edx, len_one_or_zero
    jmp .print_result

.print_result:
    call print_string

    ; -------------------------------------------------------------------------
    ; 4. Завершуємо програму
    ; -------------------------------------------------------------------------
    mov eax, 1          ; Системний виклик: 1 = sys_exit
    xor ebx, ebx        ; Код виходу 0
    int 0x80