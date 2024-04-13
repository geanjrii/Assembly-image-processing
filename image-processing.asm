.686
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib

.data?
stdInHandle dd ?
stdOutHandle dd ?

consoleCharCount dd ?
genericStrBuffer db 60 dup(?)

fileInName db 50 dup(?)
fileOutName db 50 dup(?)
colorSelection dd ?
colorChange dd ?

fileInHandle dd ?
fileOutHandle dd ?

filePixel db 3 dup(?)
bytesTransfered dd ?
fileHeader db 54 dup(?)

.data
strEnterInName db "Digite o nome do arquivo de entrada: ",0H
strEnterOutName db "Digite o nome do arquivo de saida: ",0H
strEnterColorSelection db "Escolha uma cor (0 para azul, 1 para verde ou 2 para vermelho): ", 0H
strEnterColorChange db "Escolha o valor de aumento da cor (0 a 255): ",0H

.code
FixConsoleIntIn:
  push ebp
  mov ebp, esp
  
  mov esi, [ebp+8] 
 proximo_console_int:
  mov al, [esi] ; Mover caracter atual para al
  inc esi ; Apontar para o proximo caracter
  cmp al, 48 ; Verificar se menor que ASCII 48 - FINALIZAR
  jl  terminar_console_int
  cmp al, 58 ; Verificar se menor que ASCII 58 - CONTINUAR
  jl  proximo_console_int
 terminar_console_int:
  dec esi ; Apontar para caracter anterior
  xor al, al ; 0 ou NULL
  mov [esi], al ; Inserir NULL logo apos o termino do numero

  mov esp, ebp
  pop ebp
  ret 4

FixConsoleStrIn:
  push ebp
  mov ebp, esp
 
  mov esi, [ebp+8] ; Armazenar apontador da string em esi
 proximo_console_str:
  mov al, [esi] ; Mover caracter atual para al
  inc esi ; Apontar para o proximo caracter
  cmp al, 13 ; Verificar se eh o caractere ASCII CR - FINALIZAR
  jne  proximo_console_str
  dec esi ; Apontar para caracter anterior
  xor al, al ; 0 ou NULL
  mov [esi], al ; Inserir NULL logo apos o termino do numero
 
  mov esp, ebp
  pop ebp
  ret 4
  
IncreaseColor:
  push ebp
  mov ebp, esp

  mov ebx, [ebp+8]
  mov ecx, [ebp+12]
  mov eax, 0FFH
  sub al, BYTE PTR [ebx][ecx]
  cmp eax, [ebp+16]
  jb max
  mov eax, [ebp+16]
  add BYTE PTR [ebx][ecx], al
  jmp retornar
 max:  
  mov BYTE PTR [ebx][ecx], 0FFH  
  
 retornar:  
  mov esp, ebp
  pop ebp
  ret 12


start:
  invoke GetStdHandle, STD_OUTPUT_HANDLE
  mov stdOutHandle, eax
  invoke GetStdHandle, STD_INPUT_HANDLE
  mov stdInHandle, eax

  invoke WriteConsole, stdOutHandle, addr strEnterInName, sizeof strEnterInName-1, addr consoleCharCount, NULL
  invoke ReadConsole, stdInHandle, addr fileInName, sizeof fileInName-1, addr consoleCharCount, NULL
  push offset fileInName
  call FixConsoleStrIn
  invoke WriteConsole, stdOutHandle, addr strEnterOutName, sizeof strEnterOutName-1, addr consoleCharCount, NULL
  invoke ReadConsole, stdInHandle, addr fileOutName, sizeof fileOutName-1, addr consoleCharCount, NULL
  push offset fileOutName
  call FixConsoleStrIn

  invoke WriteConsole, stdOutHandle, addr strEnterColorSelection, sizeof strEnterColorSelection-1, addr consoleCharCount, NULL
  invoke ReadConsole, stdInHandle, addr genericStrBuffer, sizeof genericStrBuffer-1, addr consoleCharCount, NULL
  push offset genericStrBuffer
  call FixConsoleIntIn
  invoke atodw, addr genericStrBuffer
  mov colorSelection, eax
  invoke WriteConsole, stdOutHandle, addr strEnterColorChange, sizeof strEnterColorChange-1, addr consoleCharCount, NULL
  invoke ReadConsole, stdInHandle, addr genericStrBuffer, sizeof genericStrBuffer-1, addr consoleCharCount, NULL
  push offset genericStrBuffer
  call FixConsoleIntIn
  invoke atodw, addr genericStrBuffer
  mov colorChange, eax

  invoke CreateFile, addr fileInName, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
  mov fileInHandle, eax
  invoke CreateFile, addr fileOutName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
  mov fileOutHandle, eax
  invoke ReadFile, fileInHandle, addr fileHeader, 54, addr bytesTransfered, NULL
  invoke WriteFile, fileOutHandle, addr fileHeader, 54, addr bytesTransfered, NULL
  
 repetir:
  invoke ReadFile, fileInHandle, addr filePixel, 3, addr bytesTransfered, NULL
  cmp bytesTransfered, 0
  je fim

  push DWORD PTR[colorChange]
  push DWORD PTR[colorSelection]
  push offset filePixel
  call IncreaseColor
  
  invoke WriteFile, fileOutHandle, addr filePixel, 3, addr bytesTransfered, NULL
  jmp repetir
  
 fim:
  invoke CloseHandle, fileInHandle
  invoke CloseHandle, fileOutHandle
  invoke ExitProcess, 0 
end start