/*
Test uCAM-III from PCs
Note: no recollection if this ever worked in the past

cc -std=c99 -Werror -o start main.c
./start [usb_interface]

*/
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <fcntl.h>    // File control definitions

#define UART_DEFAULT_PORT "/dev/ttyUSB1"
#define COMMAND_LENGTH 6

int main(int argc, char const **argv)
{
    //-------------------------------------------------------------------------
    // Try opening the UART interface
    //-------------------------------------------------------------------------
    char UART_port[16] = {0};
    if (argc > 1) {
        if (strlen(argv[1]) < 15)
            strncpy(UART_port, argv[1], 15);
    } else {
        strcpy(UART_port, UART_DEFAULT_PORT);
    }
        

    int cam = open(UART_port, O_RDWR | O_NONBLOCK);
    if (cam == -1) {
        fprintf(stderr, "No connection with %s interface.\n\n", UART_port);
        exit(EXIT_FAILURE);
    } else {
        printf("Connection to interface %s established.\n", UART_port);
    }


    //------------------Commands-----------------ID----P1----P2----P3----P4----
    const unsigned char initial[]      = {0xaa, 0x01, 0x00, 0x06, 0x03, 0x07};
    const unsigned char get_picture[]  = {0xaa, 0x04, 0x02, 0x00, 0x00, 0x00};
    const unsigned char snapshot[]     = {0xaa, 0x05, 0x01, 0x00, 0x00, 0x00};
    const unsigned char package_size[] = {0xaa, 0x06, 0x08, 0x00, 0x00, 0x00};
    const unsigned char baud_rate[]    = {0xaa, 0x07, 0x00, 0x00, 0x00, 0x00};
    const unsigned char reset[]        = {0xaa, 0x08, 0x00, 0x00, 0x00, 0x00};
    const unsigned char data[]         = {0xaa, 0x0a, 0x00, 0x00, 0x00, 0x00};
    const unsigned char sync[]         = {0xaa, 0x0d, 0x00, 0x00, 0x00, 0x00};
    const unsigned char ack[]          = {0xaa, 0x0e, 0x00, 0x00, 0x00, 0x00};
    const unsigned char nak[]          = {0xaa, 0x0f, 0x00, 0x00, 0x00, 0x00};
    const unsigned char light[]        = {0xaa, 0x13, 0x01, 0x00, 0x00, 0x00};
    const unsigned char options[]      = {0xaa, 0x14, 0x02, 0x02, 0x02, 0x00};
    const unsigned char sleep_com[]    = {0xaa, 0x15, 0x00, 0x00, 0x00, 0x00};
    //-------------------------------------------------------------------------
    // buffer to read command from cam
    unsigned char op_read[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

    
    //-------------------------------------------------------------------------
    // Synchronize with uCAM
    //-------------------------------------------------------------------------
    struct timespec ts = {0, 5000};
    int B_r = 0;
    int B_w = 0;
    int nb_try_sync = 0;

    while (nb_try_sync < 60) {
        B_w = write(cam, sync, COMMAND_LENGTH);
        if (B_w != 6) {
            fprintf(stderr, "Not every bytes where sent\n");
        }
        printf("Send %d : %d%d%d\n", nb_try_sync, sync[0], sync[1], sync[2]);

        B_r = read(cam, op_read, COMMAND_LENGTH);
        if (B_r == COMMAND_LENGTH)
            break;

        nanosleep(&ts, NULL);
        ts.tv_nsec += 1000;
        nb_try_sync++;
    }
    if (nb_try_sync == 60) {
        fprintf(stderr, "Sync failed.\nExit.\n");
        close(cam);
        exit(EXIT_FAILURE);
    }
    printf("Read : %s\n", op_read);


    //-------------------------------------------------------------------------
    // Running...
    //-------------------------------------------------------------------------
    if (memcmp(op_read, ack, 3) != 0) {
        fprintf(stderr, "Invalid ACK sync\n");
        close(cam);
        return 0;
    }
    printf("Ack sync received\n");

    B_r = read(cam, op_read, COMMAND_LENGTH);
    if (B_r != COMMAND_LENGTH || memcmp(op_read, sync) != 0) {
        fprintf(stderr, "Expecting Sync\n");
        close(cam);
        return 0;
    }
    printf("Ack sync received.\n");

    usleep(2000000); // Time to allow the cam to stabilize

    ack[2] = sync[1];
    if ((op_read[0] == ack[0] && op_read[1] == ack[1] && op_read[2] == ack[2]) == 0) {
        fprintf(stderr, "Sync ack failed.\nExit.\n");
        close(cam);
        exit( EXIT_FAILURE );
    } else {
        printf("Synchronised!.\n");
    }

    close(cam);
    printf("Exiting...\n");
    return 0;
}
