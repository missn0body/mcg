VERSION = 1.0.0
ASM = nasm
ASMFLAGS = -f elf64 -Oxv -g
LD = ld
RM = rm

BIN = mcg

.PHONY: all clean dist self

BDIR = bin
ODIR = obj
SDIR = src
DDIR = doc

SRCS = $(wildcard $(SDIR)/*.asm)
OBJS = $(patsubst $(SDIR)/%.asm, $(ODIR)/%.o, $(SRCS))

# Building -------------------------------------

all: $(BIN)

$(BIN): $(BDIR) $(ODIR) $(OBJS)
	$(LD) $(OBJS) -o $(BDIR)/$@

$(ODIR)/%.o: $(SDIR)/%.asm
	$(ASM) $(ASMFLAGS) $< -o $@

$(BDIR):
	 mkdir $@
$(ODIR):
	 mkdir $@

# Distribution ---------------------------------

dist: clean
dist: all
dist: $(DDIR)/$(BIN).7
	gzip -vk $<
	tar -czvf $(BIN)-$(VERSION).tar.gz $(BDIR)/$(BIN) $(DDIR)/* ../README.md ../UNLICENSE --transform 's,^,$(BIN)-$(VERSION)/,'
	md5sum $(BIN)-$(VERSION).tar.gz

self: clean
self: all
self: $(DDIR)/$(BIN).7
	gzip -vk $<
	sudo mkdir /usr/local/man/man7/ -p
	sudo mv $(BDIR)/$(BIN) /usr/local/bin
	sudo mv $(DDIR)/$(BIN).7.gz /usr/local/man/man7/
	sudo mandb -q

# Other ----------------------------------------

clean:
	$(RM) -f $(BDIR)/* $(ODIR)/*

