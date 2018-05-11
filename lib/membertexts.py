from BeautifulSoup import BeautifulSoup
import re, htmlentitydefs
soup = BeautifulSoup(open('tasks/data_files/member_texts.xml'))


#print soup.prettify()

#foo = soup.findAll('membership_id')
#print len(foo)


def unescape(text):
    def fixup(m):
        text = m.group(0)
        if text[:2] == "&#":
            # character reference
            try:
                if text[:3] == "&#x":
                    return unichr(int(text[3:-1], 16))
                else:
                    return unichr(int(text[2:-1]))
            except ValueError:
                pass
        else:
            # named entity
            try:
                text = unichr(htmlentitydefs.name2codepoint[text[1:-1]])
            except KeyError:
                pass
        return text # leave as is
    return re.sub("&#?\w+;", fixup, text)


from HTMLParser import HTMLParser

class MLStripper(HTMLParser):
    def __init__(self):
        self.reset()
        self.fed = []
    def handle_data(self, d):
        self.fed.append(d)
    def get_data(self):
        return ''.join(self.fed)

def strip_tags(html):
    s = MLStripper()
    s.feed(html)
    return s.get_data()





#foo = soup.find(text=re.compile("21226"))
#poo = foo.parent.parent.find('text').contents[0]
#
#print unescape(poo)
#
#poo = unescape(poo)
#
#poo = re.sub('<\/p>', '\n', poo)
#
#
#
#print "======================"
#poo = strip_tags(poo)
#apa = re.compile('<!--.*?-->', re.DOTALL)
#poo = apa.sub('', poo)
#print poo.strip()
#exit




resub = re.compile('<!--.*?-->', re.DOTALL)

for tag in soup.findAll('text'):
    content = tag.contents[0]
    content = strip_tags( re.sub('<\/p>', '\n', unescape(content)) )
    content = resub.sub('', content)
    tag.string = content.strip()


f = open('tasks/data_files/member_texts_clean.xml',"w")
f.write(str(soup))
f.close