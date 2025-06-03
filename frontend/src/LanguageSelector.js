import React from 'react';
import { useTranslation } from 'react-i18next';

const LanguageSelector = ({ user, onLanguageChange }) => {
  const { i18n, t } = useTranslation();

  const languages = [
    { code: 'en', name: t('users.languages.en'), flag: '🇺🇸' },
    { code: 'de', name: t('users.languages.de'), flag: '🇩🇪' },
    { code: 'es', name: t('users.languages.es'), flag: '🇪🇸' }
  ];

  const handleLanguageChange = async (langCode) => {
    try {
      // Change the language in i18n
      await i18n.changeLanguage(langCode);
      
      // If user is logged in, update their language preference in the backend
      if (user && onLanguageChange) {
        await onLanguageChange(langCode);
      }
    } catch (error) {
      console.error('Failed to change language:', error);
    }
  };

  return (
    <div className="relative group">
      <button className="flex items-center space-x-2 px-3 py-2 rounded-md text-sm text-gray-600 hover:text-gray-900 hover:bg-gray-100 transition-colors">
        <span className="text-lg">
          {languages.find(lang => lang.code === i18n.language)?.flag || '🌐'}
        </span>
        <span className="hidden sm:inline">
          {languages.find(lang => lang.code === i18n.language)?.name || 'Language'}
        </span>
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>
      
      <div className="absolute right-0 top-full mt-1 w-48 bg-white rounded-md shadow-lg border border-gray-200 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50">
        <div className="py-1">
          {languages.map((language) => (
            <button
              key={language.code}
              onClick={() => handleLanguageChange(language.code)}
              className={`w-full text-left px-4 py-2 text-sm hover:bg-gray-100 flex items-center space-x-3 ${
                i18n.language === language.code ? 'bg-blue-50 text-blue-600' : 'text-gray-700'
              }`}
            >
              <span className="text-lg">{language.flag}</span>
              <span>{language.name}</span>
              {i18n.language === language.code && (
                <svg className="w-4 h-4 ml-auto" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                </svg>
              )}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};

export default LanguageSelector;