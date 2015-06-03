all :  libwelcome.so

welcome.o: welcome.c
	gcc -fPIC -c -Wall welcome.c
libwelcome.so: welcome.o
	gcc -shared -Wl,-soname,libwelcome.so -o libwelcome.so welcome.o -lc -ltcl8.6
clean :
	rm  *.o *.so
