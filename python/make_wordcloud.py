import matplotlib.pyplot as plt
import numpy as np
import re
from wordcloud import WordCloud, STOPWORDS, get_single_color_func

PATH_TO_INFILE = '../../../Desktop/comps_texts.txt'
PATH_TO_OUTFILE = '../../../Desktop/comps_texts_out.txt'

stopwords = set(STOPWORDS)

text = ''
f = open(PATH_TO_INFILE, 'r')

for line in f:
    text += line
f.close()

# Remove all text between parentheses
text = re.sub(r'\([^)]*\)', '', text)
additional_stopwords = [
    'different', 'also', 'used', 'increase', 'two', 'need', 'using']

for word in additional_stopwords:
    text = text.replace(word, '')

    # Change double spaces to single
    text = text.replace('  ', ' ')

    
class GroupedColorFunc(object):
    """Create a color function object which assigns DIFFERENT SHADES of
       specified colors to certain words based on the color to words mapping.
       Uses wordcloud.get_single_color_func
       Parameters
       ----------
       color_to_words : dict(str -> list(str))
         A dictionary that maps a color to the list of words.
       default_color : str
         Color that will be assigned to a word that's not a member
         of any value from color_to_words.
    """

    def __init__(self, color_to_words, default_color):
        self.color_func_to_words = [
            (get_single_color_func(color), set(words))
            for (color, words) in color_to_words.items()]
        
        self.default_color_func = get_single_color_func(default_color)

    def get_color_func(self, word):
        """Returns a single_color_func associated with the word"""
        try:
            color_func = next(
                color_func for (color_func, words) in self.color_func_to_words
                if word in words)
        except StopIteration:
            color_func = self.default_color_func
            
        return color_func
    
    def __call__(self, word, **kwargs):
        return self.get_color_func(word)(word, **kwargs)


wordcloud = WordCloud(background_color='black', stopwords=stopwords)\
            .generate(text)
colors = ['red', 'orange', 'yellow', 'green', 'blue', 'magenta', 'cyan',
          'pink', 'purple', 'turquoise']
color_map = {color: [] for color in colors}

# Assign colors to each word randomly
for word in set(text.split()):
    color = np.random.choice(colors)
    color_map[color].append(word)

    grouped_color_func = GroupedColorFunc(color_map, 'black')

plt.imshow(wordcloud.recolor(color_func=grouped_color_func),
           interpolation='bilinear')
plt.axis('off')
plt.show()
