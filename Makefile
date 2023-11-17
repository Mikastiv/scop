NAME = zig-out/bin/scop
SCOP = scop

all: $(NAME)

$(SCOP): all

$(NAME):
	zig build -Doptimize=ReleaseSafe

clean:
	rm -rf zig-cache

fclean: clean
	rm -rf zig-out

re: fclean all

.PHONY: all clean fclean re
