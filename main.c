//============================================================================
//
//% Student Name 1: Minh Phat Tran
//% Student 1 #: 301297286
//% Student 1 userid (email): phatt (phatt@sfu.ca)
//
//% Student Name 2: Lingchong Weng
//% Student 2 #: 301308043
//% Student 2 userid (email): lwa89 (lwa89@sfu.ca)
//
//% Below, edit to list any people who helped you with the code in this file,
//%      or put �none� if nobody helped (the two of) you.
//
// Helpers: _everybody helped us/me with the assignment (list names or put �none�)__
//
// Also, list any resources beyond the course textbook and the course pages on Piazza
// that you used in making your submission.
//
// Resources:  ___________
//
//%% Instructions:
//% * Put your name(s), student number(s), userid(s) in the above section.
//% * Edit the "Helpers" line and "Resources" line.
//% * Your group name should be "A2_<userid1>_<userid2>" (eg. A2_stu1_stu2)
//% * Form groups as described at:  https://courses.cs.sfu.ca/docs/students
//% * Submit this file to courses.cs.sfu.ca
//
// Name        : main.c
// Description : Assignment 2 Program 2019
//============================================================================

#include <stddef.h>
#define MAX_SIZE_TEST 1000

typedef unsigned int bigNumTest[1 + MAX_SIZE_TEST];
typedef unsigned int bigNumN[];

int asuAdd(bigNumN bigN0P, const bigNumN bigN1P, unsigned int maxN0Size);

void halt()
{
}

/*
 *  function: asuFibonacci
 *
 *  n is the Fibonacci number that you would like to calculate.  (Our Fibonacci
 *  numbers start with f0 = 0, f1 = 1, etc., and we would like to calculate fn.)
 *
 *  The return value of the function is either n, or the largest Fibonacci number
 *  that could be accurately calculated before overflow occurred.
 *
 *  maxSize is an integer that specifies how many valid words can be stored in the
 *  bigNumN numbers.
 *
 *  bNP is a pointer to a pointer to a bigNumN number holding the Fibonacci number
 *  indicated by the return value.  bNP will either point to static array bNa or
 *  static array bNb.
 *
 */
int asuFibonacci(int n, int maxSize, bigNumN **bNP) {

	// **** modify below and fill in code and ensure proper operation including return value. ***
	static bigNumTest bNa = {1,0};
	static bigNumTest bNb = {1,1};
	int index1 = 1; //create a variable to count index

	while (index1 < n)
	{

		int temp1 = asuAdd(bNa, bNb, maxSize); //use function asuAdd
		*bNP = &bNa;

		if (temp1 == 1)
		{
			return index1; // return index of value
		}
		else if (temp1 == 0)
		{
			index1 = index1 + 1;
		}

		int temp2 = asuAdd(bNb, bNa, maxSize);
		*bNP = &bNb;

		if (temp2 == 1)
		{
			return index1; // return index of value
		}
		else if (temp2 == 0)
		{
			index1 = index1 + 1;
		}

	}

	return (n-1);  // end of function
}

int main() {
	bigNumN *fibResP = NULL;
	int i = asuFibonacci(1000000, MAX_SIZE_TEST, &fibResP);
	halt();
	return i;
}

// or move this to the assembly file
void _exit(int status) {
	volatile int x; // work around problem with xilinx system debugger.
loop:
	x++;
	goto loop;
}
