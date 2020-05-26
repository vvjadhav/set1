#a=[1,2,3,4,5,6,7,8,9]
#b=[2,4,6,8,10,3,5,7,9]
#print a
#print b

a=[1,2,3,4,5,6,7,8,9]
b=[3,2,1,6,5,4,9,8,7]
c=[0]*9

# count1=0
# rowcounter=0
# while count1 < 3:
#     y=count1
#     x=rowcounter
#     while x < 3:
#         print 'x=',x,'y=',y
#         x+=1
#         y+=3
#
#     count1+=1
# rowcounter+=3


# row 0,1,2 and column 0,3,6  1,4,7  2,5,8
# row 3,4,5 and column 0,3,6  1,4,7  2,5,8
# row 6,7,8 and column 0,3,6  1,4,7  2,5,8



z=0
counter=0



while counter < 9:
	counter1=0
	while counter1 < 3:
		x=counter
		y=counter1
		counter2=0
		print 'x',x,'y',y
		while counter2 < 3:	
			#print c[z]
			c[z]=c[z] + a[x]*b[y]
			x+=1
			y+=3
			counter2+=1
		z+=1
		counter1+=1
	counter+=3

print c







