#include <stdio.h>
extern int MaxOfThree(int, int, int);
int main()
{
printf("Maxvärdet av talen 1, -4 och -7 är %d\n", MaxOfThree(1,-4,-7));
printf("Maxvärdet av talen 2, -6 och 1 är %d\n", MaxOfThree(2, -6, 1));
printf("Maxvärdet av talen 2, 3 och 1 är %d\n", MaxOfThree(2, 3, 1));
printf("Maxvärdet av talen -2, 4 och 3 är %d\n", MaxOfThree(-2, 4, 3));
printf("Maxvärdet av talen 2, -6 och 5 är %d\n", MaxOfThree(2, -6, 5));
printf("Maxvärdet av talen 2, 4 och 6 är %d\n", MaxOfThree(2, 4, 6));
return 0;
}
